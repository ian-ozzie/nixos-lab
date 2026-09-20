{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (config.ozzie.lab) traefik;

  cfg = config.ozzie.lab.syncthing;
in
{
  options.ozzie.lab.syncthing = {
    enable = lib.mkEnableOption "opinionated syncthing config";
    directOnly = lib.mkEnableOption "limit to direct connections";

    group = lib.mkOption {
      default = options.services.syncthing.group.default;
      description = "Group to run syncthing under";
      type = lib.types.str;
    };

    user = lib.mkOption {
      default = options.services.syncthing.user.default;
      description = "User to run syncthing under";
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
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
        guiAddress = "127.0.0.80:8384";
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

      traefik = lib.mkIf traefik.enable {
        dynamicConfigOptions.http = {
          routers.syncthing = {
            entryPoints = "websecure";
            priority = "10";
            rule = "Host(`sync.${config.ozzie.lab.host.bind.domain}`)";
            service = "syncthing@file";
          };

          services.syncthing = {
            loadBalancer.servers = [ { url = "http://127.0.0.80:8384"; } ];
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
