{
  config,
  lib,
  options,
  ...
}:
let
  acmeUser = config.users.users.acme;
  caddy = config.services.caddy;
  caddyEnabled = options ? ozzie.lab.caddy.enable && config.ozzie.lab.caddy.enable;

  cfg = config.ozzie.lab.acme;
  domains = lib.unique (cfg.domains ++ cfg.wildcards);
in
{
  options.ozzie.lab.acme = {
    enable = lib.mkEnableOption "opinionated acme config";

    domains = lib.mkOption {
      default = [ ];
      description = "domains to issue certificates for";
      type = lib.types.listOf lib.types.str;
    };

    tokenFile = lib.mkOption {
      default = "/data/services/acme/.token";
      description = "file that holds the Cloudflare DNS API token";
      type = lib.types.externalPath;
    };

    wildcards = lib.mkOption {
      default = [ ];
      description = "domains to issue wildcard certificates for";
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = domains != [ ];
        message = "ozzie.lab.acme.domains or ozzie.lab.acme.wildcards must not be empty when ozzie.lab.acme.enable is true.";
      }
    ];

    security = {
      acme = {
        certs = lib.genAttrs domains (domain: {
          inherit (acmeUser) group;
          inherit domain;

          extraDomainNames = lib.optional (lib.elem domain cfg.wildcards) "*.${domain}";
        });

        defaults = {
          credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE = cfg.tokenFile;
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
        };
      };
    };

    systemd = {
      mounts = [
        {
          what = "/data/services/acme";
          where = "/var/lib/acme";
          type = "none";
          options = "bind,nofail";
          after = [ "systemd-tmpfiles-setup.service" ];
          requires = [ "systemd-tmpfiles-setup.service" ];
          before = [ "acme-setup.service" ];
          requiredBy = [ "acme-setup.service" ];
          unitConfig.RequiresMountsFor = "/data/services/acme";
        }
      ];

      tmpfiles.rules = [
        "d /data/services/acme 0755 ${acmeUser.name} ${acmeUser.group}"
      ];
    };

    users.users = lib.mkIf (caddyEnabled && domains != [ ]) {
      ${caddy.user} = {
        extraGroups = [ acmeUser.group ];
      };
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/security/acme"
    ];
  };
}
