{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) traefik;

  cfg = config.ozzie.lab.radicale;
in
{
  options.ozzie.lab.radicale = {
    enable = lib.mkEnableOption "opinionated radicale config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      radicale = {
        enable = true;
        package = with pkgs; radicale;

        settings = {
          server.hosts = [ "127.0.0.80:8388" ];
          storage.filesystem_folder = "/data/services/radicale/collections";

          auth = {
            htpasswd_encryption = "autodetect";
            htpasswd_filename = "/data/services/radicale/users";
            type = "htpasswd";
          };
        };
      };

      traefik = lib.mkIf traefik.enable {
        dynamicConfigOptions.http = {
          routers.radicale = {
            entryPoints = "websecure";
            priority = "10";
            rule = "Host(`calendar.${config.ozzie.lab.host.bind.domain}`)";
            service = "radicale@file";
          };

          services.radicale = {
            loadBalancer.servers = [ { url = "http://127.0.0.80:8388"; } ];
          };
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/radicale 0700 radicale radicale"
        "d /data/services/radicale/collections 0700 radicale radicale"
      ];
    };
  };
}
