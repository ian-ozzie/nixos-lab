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
    openssh.enable = lib.mkIf cfg.ssh true;

    forgejo = {
      enable = true;

      ssoProxy = lib.mkIf (!localApp) (
        lib.concatStringsSep "," (projectNetwork.addresses "backend" project.roles.router)
      );
    };
  };

  services = {
    forgejo = {
      database = {
        createDatabase = false;
        name = projectName;
        passwordFile = if localDatabase then null else project.mysql.passwordFile or null;
        type = "mysql";
        user = if localDatabase then config.services.forgejo.user else projectName;

        host =
          if localDatabase then
            "localhost"
          else
            projectNetwork.urlAddress (projectNetwork.address "backend" project.roles.mysql);

        socket =
          if localDatabase then
            config.services.mysql.settings.mysqld.socket or "/run/mysqld/mysqld.sock"
          else
            null;
      };

      settings.server = {
        DOMAIN = project.hostName;
        HTTP_ADDR = if localApp then "127.0.0.1" else projectNetwork.address "backend" memberName;
        HTTP_PORT = port;
        ROOT_URL = "https://${project.hostName}/";
      };
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

  systemd.services.forgejo = lib.mkIf localDatabase {
    after = [ "mysql.service" ];
    requires = [ "mysql.service" ];
  };
}
