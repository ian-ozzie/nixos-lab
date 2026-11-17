{
  config,
  lib,
  options,
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

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/networking/unifi.nix"
      "pkgs/by-name/un/unifi/package.nix"
    ];
  };
}
