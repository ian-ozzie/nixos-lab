{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) mysql openssh traefik;

  cfg = config.ozzie.lab.forgejo;
in
{
  options.ozzie.lab.forgejo = {
    enable = lib.mkEnableOption "opinionated forgejo config";

    ssh = lib.mkEnableOption "configure openssh for access" // {
      default = cfg.enable;
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "git";
      description = "User account under which Forgejo runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      forgejo = {
        enable = true;
        package = with pkgs; forgejo;
        repositoryRoot = "/data/services/forgejo/repos";
        stateDir = "/data/services/forgejo";
        user = lib.mkDefault cfg.user;

        database = {
          createDatabase = lib.mkDefault false;
          socket = lib.mkDefault "/run/mysqld/mysqld.sock";
          type = lib.mkDefault "mysql";
          user = lib.mkDefault config.services.forgejo.user;
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

      openssh = lib.mkIf (cfg.ssh && openssh.enable) {
        settings = {
          AcceptEnv = "GIT_PROTOCOL";
          AllowUsers = [ cfg.user ];
        };
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

    users.users = lib.mkIf (cfg.user == "git") {
      git = {
        inherit (config.services.forgejo) group;

        home = config.services.forgejo.stateDir;
        isSystemUser = true;
        useDefaultShell = true;

        packages = with pkgs; [
          forgejo
        ];
      };
    };
  };
}
