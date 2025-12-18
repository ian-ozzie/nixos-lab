{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) traefik;

  cfg = config.ozzie.lab.ntfy-sh;
in
{
  options.ozzie.lab.ntfy-sh = {
    enable = lib.mkEnableOption "opinionated ntfy-sh config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      ntfy-sh = {
        enable = true;
        package = with pkgs; ntfy-sh;

        settings = {
          base-url = "https://ntfy.${config.ozzie.lab.host.bind.domain}";
          listen-http = "127.0.0.80:8389";
          template-dir = "/data/services/ntfy-sh/templates";
        };
      };

      traefik = lib.mkIf traefik.enable {
        dynamicConfigOptions.http = {
          routers.ntfy = {
            entryPoints = "websecure";
            priority = "10";
            rule = "Host(`ntfy.${config.ozzie.lab.host.bind.domain}`)";
            service = "ntfy@file";
          };

          services.ntfy = {
            loadBalancer.servers = [ { url = "http://127.0.0.80:8389"; } ];
          };
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/ntfy-sh 0700 ntfy-sh ntfy-sh"
        "d /data/services/ntfy-sh/templates 0700 ntfy-sh ntfy-sh"
      ];
    };
  };
}
