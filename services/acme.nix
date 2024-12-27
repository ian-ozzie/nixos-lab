{
  config,
  lib,
  ...
}:
let
  inherit (config.ozzie.lab) traefik;

  cfg = config.ozzie.lab.acme;
in
{
  options.ozzie.lab.acme = {
    enable = lib.mkEnableOption "opinionated acme config";
  };

  config = lib.mkIf cfg.enable {
    security = {
      acme = {
        acceptTerms = true;
        preliminarySelfsigned = false;

        certs."${config.ozzie.lab.host.bind.domain}" = {
          domain = "${config.ozzie.lab.host.bind.domain}";
          extraDomainNames = [ "*.${config.ozzie.lab.host.bind.domain}" ];
        };

        defaults = {
          dnsPropagationCheck = true;
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          environmentFile = "/data/services/acme/.env";
          group = "acme";
        };
      };
    };

    services = {
      traefik = lib.mkIf traefik.enable {
        dynamicConfigOptions.tls.certificates = [
          {
            certFile = "/var/lib/acme/${config.ozzie.lab.host.bind.domain}/fullchain.pem";
            keyFile = "/var/lib/acme/${config.ozzie.lab.host.bind.domain}/key.pem";
            stores = "default";
          }
        ];
      };
    };

    users.users = {
      traefik = lib.mkIf traefik.enable {
        extraGroups = [ "acme" ];
      };
    };
  };
}
