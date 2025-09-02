{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) mysql traefik;

  cfg = config.ozzie.lab.forgejo;
in
{
  options.ozzie.lab.forgejo = {
    enable = lib.mkEnableOption "opinionated forgejo config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      forgejo = {
        enable = true;
        package = with pkgs; forgejo;
        repositoryRoot = "/data/services/forgejo/repos";
        stateDir = "/data/services/forgejo";

        database = {
          createDatabase = lib.mkDefault false;
          socket = lib.mkDefault "/run/mysqld/mysqld.sock";
          type = lib.mkDefault "mysql";
        };

        settings = {
          log.LEVEL = "Info";
          session.COOKIE_SECURE = true;

          server = {
            DOMAIN = "git.${config.ozzie.lab.host.bind.domain}";
            HTTP_ADDR = "127.0.0.80";
            HTTP_PORT = 8386;
            PROTOCOL = "http";
            ROOT_URL = "https://git.${config.ozzie.lab.host.bind.domain}/";
            SSH_PORT = 22;
          };
        };
      };

      mysql = lib.mkIf mysql.enable {
        ensureDatabases = [ config.services.forgejo.database.name ];

        ensureUsers = [
          {
            name = config.services.forgejo.database.user;

            ensurePermissions = {
              "${config.services.forgejo.database.name}.*" = "ALL PRIVILEGES";
            };
          }
        ];
      };

      mysqlBackup = lib.mkIf mysql.backup.enable {
        databases = [ config.services.forgejo.database.name ];
      };

      traefik = lib.mkIf traefik.enable {
        dynamicConfigOptions.http = {
          routers.forgejo = {
            entryPoints = "websecure";
            priority = "10";
            rule = "Host(`git.${config.ozzie.lab.host.bind.domain}`)";
            service = "forgejo@file";
          };

          services.forgejo = {
            loadBalancer.servers = [ { url = "http://127.0.0.80:8386"; } ];
          };
        };
      };
    };
  };
}
