{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.gatus;
  settingsFormat = pkgs.formats.yaml { };
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
  };

  config = lib.mkIf cfg.enable {
    ozzie.lab.caddy = lib.mkIf (cfg.expose != null) {
      enable = true;

      sites."${cfg.host}.${cfg.domain}" = {
        listenAddresses = [ cfg.expose ];
        upstreams = [ "127.0.0.1:8387" ];
      };
    };

    services.gatus = {
      enable = true;

      settings = {
        endpoints = lib.attrValues cfg.endpoints;

        web = {
          address = lib.mkDefault "127.0.0.1";
          port = lib.mkDefault 8387;
        };
      };
    };
  };
}
