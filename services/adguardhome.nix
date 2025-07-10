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

    bind = lib.mkOption {
      default = [ "127.0.0.80" ];
      description = "Default host to bind dns resolver to";
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.nameservers = [ "127.0.0.80" ];

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

          clients = {
            persistent = [
              {
                ids = [ "127.0.0.1" ];
                name = "Local";
                uid = "0197ee4d-041a-7ce9-af4f-a11bfdce5193";
                use_global_blocked_services = true;
                use_global_settings = true;
              }
            ];
          };

          dns = {
            aaaa_disabled = true;
            allowed_clients = [ "127.0.0.1" ];
            bind_hosts = cfg.bind;
            cache_optimistic = true;
            cache_size = 16777216;
            cache_ttl_max = 14400;
            cache_ttl_min = 900;
            enable_dnssec = true;
            fallback_dns = [ "https://9.9.9.9/dns-query" ];
            ports = "53";
            ratelimit_whitelist = [ "127.0.0.1" ];
            upstream_dns = [ "https://1.1.1.1/dns-query" ];

            bootstrap_dns = [
              "1.1.1.1"
              "9.9.9.9"
            ];
          };

          filtering = {
            blocking_mode = "refused";
            filtering_enabled = true;
            filters_update_interval = 168;
          };

          querylog = {
            interval = "168h";
          };

          statistics = {
            interval = "168h";
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
