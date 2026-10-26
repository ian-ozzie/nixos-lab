{
  localApp,
  localDatabase,
  port,
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
  clients =
    projectNetwork.addresses "backend" project.roles.router
    ++ projectNetwork.addresses "backend" (project.roles.monitor or [ ]);

  databaseHost = projectNetwork.urlAddress (
    projectNetwork.address "backend" project.roles.postgresql
  );
in
{
  ozzie.lab.atuin.enable = true;

  services = {
    atuin = {
      inherit port;

      host = if localApp then "127.0.0.1" else projectNetwork.address "backend" memberName;

      database.uri =
        if localDatabase then "postgresql://atuin@localhost/${projectName}?host=/run/postgresql" else null;
    };

    firewalld.zones.nixos-fw-default.rules = lib.mkIf (!localApp) (
      map (client: {
        "@family" = projectNetwork.addressFamily client;
        accept = "";
        source."@address" = client;

        port = {
          "@port" = toString port;
          "@protocol" = "tcp";
        };
      }) clients
    );
  };

  systemd.services.atuin = lib.mkMerge [
    (lib.mkIf localDatabase {
      after = [ "postgresql-accounts.service" ];
      requires = [ "postgresql-accounts.service" ];
    })

    (lib.mkIf (!localDatabase) {
      serviceConfig = {
        LoadCredential = [ "postgresql-password:${project.postgresql.passwordFile or ""}" ];

        ExecStart = lib.mkForce (
          pkgs.writeShellScript "atuin-server" ''
            set -euo pipefail
            password=$(< "$CREDENTIALS_DIRECTORY/postgresql-password")
            test -n "$password"
            password=$(printf '%s' "$password" | ${pkgs.jq}/bin/jq -sRr @uri)

            export ATUIN_DB_URI="postgresql://"${lib.escapeShellArg projectName}":$password@"${lib.escapeShellArg databaseHost}":5432/"${lib.escapeShellArg projectName}
            unset password

            exec ${lib.getExe' config.services.atuin.package "atuin-server"} start
          ''
        );
      };
    })
  ];
}
