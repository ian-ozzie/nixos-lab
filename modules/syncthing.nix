{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.syncthing;
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
      description = "reverse proxy the gui through caddy";
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
        upstreams = [ "127.0.0.1:8384" ];
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [ 22000 ];
    };

    services = {
      syncthing = {
        inherit (cfg) group user;

        configDir = "/data/services/syncthing/config";
        dataDir = "/data/services/syncthing";
        enable = true;
        overrideDevices = false;
        overrideFolders = false;
        package = with pkgs; syncthing;

        settings = {
          gui = {
            insecureAdminAccess = true;
            insecureSkipHostcheck = true;
          };

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
        "d /data/services/syncthing 0700 ${cfg.user} ${cfg.group}"
      ];
    };
  };
}
