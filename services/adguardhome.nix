{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) traefik;

  cfg = config.ozzie.lab.adguardhome;
in
{
  options.ozzie.lab.adguardhome = {
    enable = lib.mkEnableOption "opinionated adguardhome config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      adguardhome = {
        allowDHCP = false;
        enable = true;
        host = "127.0.0.80";
        mutableSettings = false;
        openFirewall = false;
        package = with pkgs; adguardhome;
        port = 8053;

        settings = {
          schema_version = 28;
          theme = "dark";
          users = [ ];

          dns = {
            bind_hosts = [ "127.0.0.80" ];
            fallback_dns = [ "https://9.9.9.9/dns-query" ];
            ports = "53";
            upstream_dns = [ "https://1.1.1.1/dns-query" ];

            bootstrap_dns = [
              "1.1.1.1"
              "9.9.9.9"
            ];
          };

          filtering = {
            filtering_enabled = true;
            filters_update_interval = 168;
          };
        };
      };

      traefik = lib.mkIf traefik.enable {
        dynamicConfigOptions.http = {
          routers.dns-web = {
            entryPoints = "websecure";
            priority = "10";
            rule = "Host(`dns.${config.ozzie.lab.host.bind.domain}`)";
            service = "dns-web@file";
          };

          services.dns-web = {
            loadBalancer.servers = [ { url = "http://127.0.0.80:8053"; } ];
          };
        };
      };
    };
  };
}
