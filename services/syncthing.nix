{
  config,
  lib,
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

    group = lib.mkOption {
      default = config.services.syncthing.group;
      description = "Group to run syncthing under";
      type = lib.types.str;
    };

    user = lib.mkOption {
      default = config.services.syncthing.user;
      description = "User to run syncthing under";
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 22000 ];

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
        relay.enable = false;

        settings.gui = {
          insecureAdminAccess = true;
          insecureSkipHostcheck = true;
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
