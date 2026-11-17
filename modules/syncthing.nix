{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.syncthing;
  service = config.services.syncthing;
in
{
  options.ozzie.lab.syncthing = {
    enable = lib.mkEnableOption "opinionated syncthing config";
    directOnly = lib.mkEnableOption "limit to direct connections";

    domain = lib.mkOption {
      description = "Domain to expose syncthing under";
      type = lib.types.str;
    };

    expose = lib.mkOption {
      default = null;
      description = "IP to expose syncthing on via caddy, null to disable";
      type = lib.types.nullOr lib.types.str;
    };

    group = lib.mkOption {
      default = options.services.syncthing.group.default;
      description = "Group to run syncthing under";
      type = lib.types.str;
    };

    host = lib.mkOption {
      default = "sync";
      description = "Host prefix to expose syncthing with domain";
      type = lib.types.str;
    };

    user = lib.mkOption {
      default = options.services.syncthing.user.default;
      description = "User to run syncthing under";
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    ozzie.lab.caddy = lib.mkIf (cfg.expose != null) {
      enable = true;

      sites."${cfg.host}.${cfg.domain}" = {
        listenAddresses = [ cfg.expose ];
        upstreams = [ service.guiAddress ];
      };
    };

    services = {
      syncthing = {
        configDir = lib.mkDefault "/data/services/syncthing/config";
        dataDir = lib.mkDefault "/data/services/syncthing";
        enable = true;
        group = lib.mkDefault cfg.group;
        openDefaultPorts = lib.mkDefault true;
        overrideDevices = lib.mkDefault false;
        overrideFolders = lib.mkDefault false;
        user = lib.mkDefault cfg.user;

        settings = {
          options = lib.mkIf cfg.directOnly {
            globalAnnounceEnabled = false;
            natEnabled = false;
            relaysEnabled = false;
            stunKeepaliveStartS = 0;
          };
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d ${service.dataDir} 0700 ${service.user} ${service.group}"
      ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/networking/syncthing.nix"
      "pkgs/by-name/sy/syncthing/package.nix"
    ];
  };
}
