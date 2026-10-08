{
  localDatabase,
  project,
  projectName,
  projectNetwork,
  ...
}:
{
  config,
  lib,
  memberName,
  pkgs,
  ...
}:
let
  databaseHost = urlAddress (projectNetwork.address "backend" project.roles.mysql);
  databaseSocket = config.services.mysql.settings.mysqld.socket or "/run/mysqld/mysqld.sock";
  databaseUser = config.users.users.vaultwarden.name;
  urlAddress = address: if lib.hasInfix ":" address then "[${address}]" else address;

  clients =
    projectNetwork.addresses "backend" project.roles.router
    ++ projectNetwork.addresses "backend" (project.roles.monitor or [ ]);
in
{
  ozzie.lab.vaultwarden.enable = true;

  services = {
    vaultwarden.config = {
      DATABASE_URL = lib.mkIf localDatabase "mysql://${databaseUser}@localhost/${projectName}?unix_socket=${databaseSocket}";
      DATABASE_URL_FILE = lib.mkIf (!localDatabase) "/run/vaultwarden/database-url";
      DOMAIN = "https://${project.hostName}";
      ROCKET_ADDRESS = projectNetwork.address "backend" memberName;
    };

    firewalld.zones.nixos-fw-default.rules = map (client: {
      "@family" = if lib.hasInfix ":" client then "ipv6" else "ipv4";
      accept = "";
      source."@address" = client;

      port = {
        "@port" = toString config.services.vaultwarden.config.ROCKET_PORT;
        "@protocol" = "tcp";
      };
    }) clients;
  };

  systemd.services.vaultwarden = lib.mkMerge [
    (lib.mkIf localDatabase {
      after = [ "mysql.service" ];
      requires = [ "mysql.service" ];
    })

    (lib.mkIf (!localDatabase) {
      preStart = ''
        password=$(< "$CREDENTIALS_DIRECTORY/mysql-password")
        test -n "$password"
        password=$(printf '%s' "$password" | ${pkgs.jq}/bin/jq -sRr @uri)

        printf 'mysql://%s:%s@%s/%s' \
          ${lib.escapeShellArg projectName} "$password" \
          ${lib.escapeShellArg databaseHost} ${lib.escapeShellArg projectName} \
          > /run/vaultwarden/database-url

        unset password
      '';

      serviceConfig = {
        LoadCredential = [ "mysql-password:${project.mysql.passwordFile or ""}" ];
        RuntimeDirectory = "vaultwarden";
        RuntimeDirectoryMode = "0700";
      };
    })
  ];
}
