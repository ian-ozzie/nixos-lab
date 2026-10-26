{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.unifi;
in
{
  options.ozzie.lab.unifi = {
    enable = lib.mkEnableOption "opinionated unifi config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      unifi = {
        enable = true;
        mongodbPackage = with pkgs; mongodb-ce;
        openFirewall = false;
        unifiPackage = with pkgs; unifi;
      };
    };

    systemd = {
      services = {
        unifi = {
          serviceConfig.BindPaths = [ "/data/services/unifi:/var/lib/unifi/data" ];
        };
      };

      tmpfiles.rules = [
        "d /data/services/unifi 0700 unifi unifi"
      ];
    };
  };
}
