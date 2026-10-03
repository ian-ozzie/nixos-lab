{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) acme;

  cfg = config.ozzie.lab.caddy;

  siteModule = { name, config, ... }: {
    options = {
      domain = lib.mkOption {
        default = lib.concatStringsSep "." (lib.tail (lib.splitString "." config.hostname));
        defaultText = lib.literalExpression "site hostname with its first label removed";
        description = "domain of the ACME certificate to use, or null to use internal TLS";
        type = lib.types.nullOr lib.types.str;
      };

      extraConfig = lib.mkOption {
        default = "";
        description = "extra configuration for the site block";
        type = lib.types.lines;

        example = ''
          encode zstd gzip
          header X-Content-Type-Options nosniff
        '';
      };

      hostname = lib.mkOption {
        default = name;
        defaultText = lib.literalExpression "site name";
        description = "hostname to serve the site on";
        type = lib.types.str;
      };

      listenAddresses = lib.mkOption {
        default = [ ];
        description = "addresses to bind the site to";
        type = lib.types.listOf lib.types.str;
      };

      proxyConfig = lib.mkOption {
        default = "";
        description = "extra configuration for the reverse_proxy block";
        example = "lb_policy cookie";
        type = lib.types.lines;
      };

      upstreams = lib.mkOption {
        description = "addresses to proxy requests to";
        example = [ "10.0.0.2:80" ];
        type = lib.types.nonEmptyListOf lib.types.str;
      };
    };
  };
in
{
  options.ozzie.lab.caddy = {
    enable = lib.mkEnableOption "opinionated caddy config";
    package = lib.mkPackageOption pkgs "caddy" { };

    sites = lib.mkOption {
      default = { };
      description = "sites to reverse proxy";
      type = lib.types.attrsOf (lib.types.submodule siteModule);
    };
  };

  config = lib.mkIf cfg.enable {
    ozzie.lab.acme.domains = lib.mkIf acme.enable (
      lib.unique (
        lib.filter (domain: domain != null) (lib.mapAttrsToList (_: site: site.domain) cfg.sites)
      )
    );

    services.caddy = {
      inherit (cfg) package;

      enable = true;
      dataDir = "/data/services/caddy";
      openFirewall = lib.mkDefault true;

      virtualHosts = lib.mapAttrs (_: site: {
        inherit (site) listenAddresses;

        hostName = site.hostname;
        useACMEHost = if acme.enable then site.domain else null;

        extraConfig = ''
          ${lib.optionalString (!acme.enable || site.domain == null) "tls internal"}

          ${site.extraConfig}

          reverse_proxy ${lib.concatStringsSep " " site.upstreams} {
            ${site.proxyConfig}
          }
        '';
      }) cfg.sites;
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/caddy 0700 caddy caddy"
        "d /var/log/caddy 0755 caddy caddy"
      ];
    };
  };
}
