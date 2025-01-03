{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.traefik;
in
{
  options.ozzie.lab.traefik = {
    enable = lib.mkEnableOption "opinionated traefik config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      traefik = {
        enable = true;
        package = with pkgs; traefik;

        dynamicConfigOptions.http = {
          routers = {
            traefik = {
              entryPoints = "websecure";
              priority = "10";
              rule = "Host(`traefik.${config.ozzie.lab.host.bind.domain}`)";
              service = "api@internal";
            };
          };
        };

        staticConfigOptions = {
          api.dashboard = true;

          entryPoints = {
            web = {
              address = "127.0.0.80:80";
            };

            websecure = {
              address = "${config.ozzie.lab.host.bind.ip}:443";
              http.tls = true;
            };
          };

          global = {
            checkNewVersion = false;
            sendAnonymousUsage = false;
          };
        };
      };
    };
  };
}
