{
  config,
  lib,
  ...
}:
let
  inherit (config.ozzie.lab) traefik;

  cfg = config.ozzie.lab.komga;
in
{
  options.ozzie.lab.komga = {
    enable = lib.mkEnableOption "opinionated komga config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      komga = {
        enable = true;
        stateDir = "/data/services/komga";
      };

      traefik = lib.mkIf traefik.enable {
        dynamicConfigOptions.http = {
          routers.komga = {
            entryPoints = "websecure";
            priority = "10";
            rule = "Host(`komga.${config.ozzie.lab.host.bind.domain}`)";
            service = "komga@file";
          };

          services.komga = {
            loadBalancer.servers = [ { url = "http://127.0.0.80:8386"; } ];
          };
        };
      };
    };
  };
}
