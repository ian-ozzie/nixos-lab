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
    enableLog = lib.mkEnableOption "whether to enable access log";
    expose = lib.mkEnableOption "whether to expose the traefik interface";

    domain = lib.mkOption {
      default = config.ozzie.lab.host.bind.domain;
      description = "domain to expose the traefik interface on";
      type = lib.types.str;
    };

    subdomain = lib.mkOption {
      default = "traefik";
      description = "subdomain to expose the traefik interface on";
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      traefik = {
        dataDir = "/data/services/traefik";
        enable = true;
        package = with pkgs; traefik;

        dynamicConfigOptions.http = {
          middlewares.ci-ip-allow.ipAllowList.sourceRange = [ "127.0.0.1" ];

          routers = {
            traefik = lib.mkIf cfg.expose {
              entryPoints = "websecure";
              priority = "10";
              rule = "Host(`${cfg.subdomain}.${cfg.domain}`)";
              service = "api@internal";
            };
          };
        };

        staticConfigOptions = {
          api.dashboard = true;

          accessLog = lib.mkIf cfg.enableLog {
            filePath = "${config.services.traefik.dataDir}/access.log";
          };

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
