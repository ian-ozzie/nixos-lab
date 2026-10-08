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
  ...
}:
let
  cfg = config.ozzie.lab.forgejo;

  clients =
    projectNetwork.addresses "backend" project.roles.router
    ++ projectNetwork.addresses "backend" (project.roles.monitor or [ ]);
in
{
  ozzie.lab = {
    forgejo.enable = true;
    openssh.enable = lib.mkIf cfg.ssh true;
  };

  services = {
    forgejo = {
      database = {
        createDatabase = false;
        host = if localDatabase then "localhost" else projectNetwork.address "backend" project.roles.mysql;
        name = projectName;
        passwordFile = if localDatabase then null else project.mysql.passwordFile or null;
        type = "mysql";
        user = if localDatabase then config.services.forgejo.user else projectName;

        socket =
          if localDatabase then
            config.services.mysql.settings.mysqld.socket or "/run/mysqld/mysqld.sock"
          else
            null;
      };

      settings.server = {
        DOMAIN = project.hostName;
        HTTP_ADDR = projectNetwork.address "backend" memberName;
        ROOT_URL = "https://${project.hostName}/";
      };
    };

    firewalld.zones.nixos-fw-default.rules = map (client: {
      "@family" = if lib.hasInfix ":" client then "ipv6" else "ipv4";
      accept = "";
      source."@address" = client;

      port = {
        "@port" = "8386";
        "@protocol" = "tcp";
      };
    }) clients;

    openssh.settings = lib.mkIf cfg.ssh {
      AcceptEnv = [ "GIT_PROTOCOL" ];
      AllowUsers = [ config.services.forgejo.user ];
    };
  };

  systemd.services.forgejo = lib.mkIf localDatabase {
    after = [ "mysql.service" ];
    requires = [ "mysql.service" ];
  };
}
