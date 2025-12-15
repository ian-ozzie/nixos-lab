{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) mysql traefik;

  cfg = config.ozzie.lab.vaultwarden;
in
{
  options.ozzie.lab.vaultwarden = {
    enable = lib.mkEnableOption "opinionated vaultwarden config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      vaultwarden = {
        dbBackend = "mysql";
        enable = true;
        package = with pkgs; vaultwarden;

        config = {
          # TODO: SMTP configuration to allow invites/alerts
          DATABASE_URL = "mysql://vaultwarden@localhost/vaultwarden?unix_socket=/run/mysqld/mysqld.sock";
          DOMAIN = "https://vaultwarden.${config.ozzie.lab.host.bind.domain}";
          ROCKET_ADDRESS = "127.0.0.80";
          ROCKET_LOG = "critical";
          ROCKET_PORT = 8387;
          SIGNUPS_ALLOWED = lib.mkDefault false;
        };
      };

      mysql = lib.mkIf mysql.enable {
        ensureDatabases = [ "vaultwarden" ];

        ensureUsers = [
          {
            name = "vaultwarden";

            ensurePermissions = {
              "vaultwarden.*" = "ALL PRIVILEGES";
            };
          }
        ];
      };

      mysqlBackup = lib.mkIf mysql.backup.enable {
        databases = [ "vaultwarden" ];
      };

      traefik = lib.mkIf traefik.enable {
        dynamicConfigOptions.http = {
          routers.vaultwarden = {
            entryPoints = "websecure";
            priority = "10";
            rule = "Host(`vaultwarden.${config.ozzie.lab.host.bind.domain}`)";
            service = "vaultwarden@file";
          };

          services.vaultwarden = {
            loadBalancer.servers = [ { url = "http://127.0.0.80:8387"; } ];
          };
        };
      };
    };
  };
}
