{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) traefik;

  cfg = config.ozzie.lab.ncps;
in
{
  options.ozzie.lab.ncps = {
    enable = lib.mkEnableOption "opinionated ncps config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      ncps = {
        enable = true;
        package = with pkgs; ncps;
        server.addr = "${config.ozzie.lab.host.bind.ip}:8385";

        cache = {
          allowPutVerb = true;
          dataPath = "/cache/services/ncps";
          hostName = "ncps.${config.ozzie.lab.host.bind.domain}";
          maxSize = "64G";
        };

        upstream = {
          caches = [ "https://cache.nixos.org" ];
          publicKeys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
        };
      };

      traefik = lib.mkIf traefik.enable {
        dynamicConfigOptions.http = {
          routers.ncps = {
            entryPoints = "websecure";
            priority = "10";
            rule = "Host(`ncps.${config.ozzie.lab.host.bind.domain}`) && !Method(`PUT`)";
            service = "ncps@file";
          };

          routers.ncps-put = {
            entryPoints = "websecure";
            middlewares = [ "ci-ip-allow" ];
            priority = "10";
            rule = "Host(`ncps.${config.ozzie.lab.host.bind.domain}`) && Method(`PUT`)";
            service = "ncps@file";
          };

          services.ncps = {
            loadBalancer.servers = [ { url = "http://${config.ozzie.lab.host.bind.ip}:8385"; } ];
          };
        };
      };
    };
  };
}
