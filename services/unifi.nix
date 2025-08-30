{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) traefik;

  cfg = config.ozzie.lab.unifi;
in
{
  options.ozzie.lab.unifi = {
    enable = lib.mkEnableOption "opinionated unifi config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      unifi = {
        enable = true;
        mongodbPackage = with pkgs; mongodb-7_0;
        openFirewall = false;
        unifiPackage = with pkgs; unifi;
      };

      traefik = lib.mkIf traefik.enable {
        staticConfigOptions.serversTransport.insecureSkipVerify = true;

        dynamicConfigOptions.http = {
          routers.unifi = {
            entryPoints = "websecure";
            priority = "10";
            rule = "Host(`unifi.${config.ozzie.lab.host.bind.domain}`)";
            service = "unifi@file";
          };

          routers.unifi-inform = {
            entryPoints = "web";
            priority = "10";
            rule = "Host(`unifi.${config.ozzie.lab.host.bind.domain}`) && Path(`/inform`)";
            service = "unifi-inform@file";
          };

          services.unifi = {
            loadBalancer.servers = [ { url = "https://127.0.0.1:8443"; } ];
          };

          services.unifi-inform = {
            loadBalancer.servers = [ { url = "http://127.0.0.1:8080"; } ];
          };
        };
      };
    };

    systemd = {
      services = {
        unifi = {
          serviceConfig.BindPaths = [ "/data/services/unifi:/var/lib/unifi/data" ];
        };
      };
    };
  };
}
