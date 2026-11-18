{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) acme;

  cfg = config.ozzie.lab.caddy;
  service = config.services.caddy;
  isHttp = site: lib.hasPrefix "http://" site.hostname;

  siteModule = { name, config, ... }: {
    options = {
      authorizationPolicy = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.str;
      };

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
        default = [ ];
        description = "addresses to proxy requests to";
        example = [ "10.0.0.2:80" ];
        type = lib.types.listOf lib.types.str;
      };
    };
  };
in
{
  options.ozzie.lab.caddy = {
    enable = lib.mkEnableOption "opinionated caddy config";

    environmentFile = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.path;
    };

    security = {
      enable = lib.mkEnableOption "opinionated caddy-security config";

      extraConfig = lib.mkOption {
        default = "";
        type = lib.types.lines;
      };

      local = lib.mkOption {
        default = false;
        type = lib.types.bool;
      };

      package = lib.mkOption {
        type = lib.types.package;

        default = pkgs.caddy.withPlugins {
          hash = "sha256-DKuYSDleJfcmVeneA9/ksjJDIvUtY7tykVZssx694BA=";
          plugins = [ "github.com/greenpau/caddy-security@v1.6.2" ];
        };
      };

      persistState = lib.mkOption {
        default = false;
        type = lib.types.bool;
      };

      portals = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.lines;
      };

      policies = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.lines;
      };
    };

    sites = lib.mkOption {
      default = { };
      description = "sites to serve";
      type = lib.types.attrsOf (lib.types.submodule siteModule);
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.mapAttrsToList (name: site: {
      assertion = site.authorizationPolicy == null || cfg.security.enable;
      message = "ozzie.lab.caddy: site '${name}' requires security.enable when authorizationPolicy is configured";
    }) cfg.sites;

    ozzie.lab.acme.wildcards = lib.mkIf acme.enable (
      lib.unique (
        lib.filter (domain: domain != null) (
          lib.mapAttrsToList (_: site: if isHttp site then null else site.domain) cfg.sites
        )
      )
    );

    ozzie.lab.caddy.security = {
      enable = lib.mkIf (cfg.security.local || cfg.security.persistState) (lib.mkDefault true);

      extraConfig = lib.mkMerge [
        (lib.mkIf cfg.security.local ''
          local identity store localdb {
            realm local
            path ${builtins.toJSON "${service.dataDir}/users.json"}
          }
        '')

        (lib.mkIf cfg.security.persistState ''
          state {
            directory ${builtins.toJSON "${service.dataDir}/runtime"}
          }
        '')
      ];

      portals.local = lib.mkIf cfg.security.local ''
        enable identity store localdb
        enable admin api
      '';
    };

    services.caddy = {
      dataDir = lib.mkDefault "/data/services/caddy";
      enable = true;
      enableReload = lib.mkIf cfg.security.persistState false;
      environmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
      openFirewall = lib.mkDefault true;
      package = lib.mkIf cfg.security.enable cfg.security.package;

      globalConfig = lib.mkIf cfg.security.enable ''
        security {
          ${cfg.security.extraConfig}

          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: body: ''
              authentication portal ${builtins.toJSON name} {
                ${body}
              }
            '') cfg.security.portals
          )}

          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: body: ''
              authorization policy ${builtins.toJSON name} {
                ${body}
              }
            '') cfg.security.policies
          )}
        }
      '';

      virtualHosts = lib.mapAttrs (_: site: {
        inherit (site) listenAddresses;

        hostName = site.hostname;
        useACMEHost = if acme.enable && !isHttp site then site.domain else null;

        extraConfig = ''
          ${lib.optionalString (!isHttp site && (!acme.enable || site.domain == null)) "tls internal"}

          ${lib.optionalString (site.authorizationPolicy != null) ''
            authorize with ${builtins.toJSON site.authorizationPolicy}
          ''}

          ${site.extraConfig}

          ${lib.optionalString (site.upstreams != [ ]) ''
            reverse_proxy ${lib.concatStringsSep " " site.upstreams} {
              ${site.proxyConfig}
            }
          ''}
        '';
      }) cfg.sites;
    };

    systemd = {
      tmpfiles.rules = [
        "d ${service.dataDir} 0700 ${service.user} ${service.group}"
        "d ${service.logDir} 0755 ${service.user} ${service.group}"
      ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/web-servers/caddy"
      "pkgs/by-name/ca/caddy/package.nix"
    ];
  };
}
