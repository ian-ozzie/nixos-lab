{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.gatus;
  gatus = config.services.gatus;
  storageDir = dirOf gatus.settings.storage.path;
  settingsFormat = pkgs.formats.yaml { };

  webAddress =
    if lib.hasInfix ":" gatus.settings.web.address then
      "[${gatus.settings.web.address}]"
    else
      gatus.settings.web.address;
in
{
  options.ozzie.lab.gatus = {
    enable = lib.mkEnableOption "opinionated gatus config";

    domain = lib.mkOption {
      type = lib.types.str;
    };

    endpoints = lib.mkOption {
      default = { };

      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            freeformType = settingsFormat.type;

            options = {
              name = lib.mkOption {
                default = name;
                type = lib.types.str;
              };

              interval = lib.mkOption {
                default = "30s";
                type = lib.types.str;
              };
            };
          }
        )
      );
    };

    expose = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.str;
    };

    host = lib.mkOption {
      default = "gatus";
      type = lib.types.str;
    };

    ntfy = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    ozzie.lab.caddy = lib.mkIf (cfg.expose != null) {
      enable = true;

      sites."${cfg.host}.${cfg.domain}" = {
        listenAddresses = [ cfg.expose ];
        upstreams = [ "${webAddress}:${toString gatus.settings.web.port}" ];
      };
    };

    services.gatus = {
      enable = true;

      settings = {
        alerting = {
          ntfy = lib.mkIf (cfg.ntfy != null) {
            topic = "gatus";
            url = cfg.ntfy;

            default-alert = {
              failure-threshold = 3;
              send-on-resolved = true;
              success-threshold = 2;
            };
          };
        };

        endpoints = map (
          endpoint: lib.optionalAttrs (cfg.ntfy != null) { alerts = [ { type = "ntfy"; } ]; } // endpoint
        ) (lib.attrValues cfg.endpoints);

        storage = {
          type = lib.mkDefault "sqlite";
          path = lib.mkDefault "/data/services/gatus/gatus.db";
        };

        web = {
          address = lib.mkDefault "127.0.0.1";
          port = lib.mkDefault 8387;
        };
      };
    };

    users = {
      groups.gatus = { };

      users.gatus = {
        group = "gatus";
        isSystemUser = true;
      };
    };

    systemd = {
      services.gatus.serviceConfig.ReadWritePaths = lib.mkIf (gatus.settings.storage.type == "sqlite") [
        storageDir
      ];

      tmpfiles.rules = lib.mkIf (gatus.settings.storage.type == "sqlite") [
        "d ${storageDir} 0700 gatus gatus"
      ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/monitoring/gatus.nix"
      "pkgs/by-name/ga/gatus/package.nix"
    ];
  };
}
