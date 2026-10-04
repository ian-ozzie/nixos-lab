{
  config,
  lib,
  ...
}:
let
  inherit (config.ozzie.lab) caddy traefik;

  cfg = config.ozzie.lab.acme;
in
{
  options.ozzie.lab.acme = {
    enable = lib.mkEnableOption "opinionated acme config";

    domains = lib.mkOption {
      default = [ config.ozzie.lab.host.bind.domain ];
      description = "domains to issue wildcard certificates for";
      type = lib.types.listOf lib.types.str;
    };

    tokenFile = lib.mkOption {
      default = "/data/services/acme/.token";
      description = "file that holds the Cloudflare DNS API token";
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    security = {
      acme = {
        acceptTerms = true;

        certs = lib.genAttrs cfg.domains (domain: {
          inherit domain;

          extraDomainNames = [ "*.${domain}" ];
          group = "acme";

          reloadServices =
            lib.optional caddy.enable "caddy.service" ++ lib.optional traefik.enable "traefik.service";
        });

        defaults = {
          credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE = cfg.tokenFile;
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
        };
      };
    };

    services = {
      traefik = lib.mkIf traefik.enable {
        dynamicConfigOptions.tls.certificates = map (domain: {
          certFile = "/var/lib/acme/${domain}/fullchain.pem";
          keyFile = "/var/lib/acme/${domain}/key.pem";
          stores = "default";
        }) cfg.domains;
      };
    };

    systemd = {
      tmpfiles.rules = lib.mkIf (cfg.tokenFile == "/data/services/acme/.token") [
        "d /data/services/acme 0700 acme acme"
      ];
    };

    users.users = {
      caddy = lib.mkIf caddy.enable {
        extraGroups = [ "acme" ];
      };

      traefik = lib.mkIf traefik.enable {
        extraGroups = [ "acme" ];
      };
    };
  };
}
