{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.actual;
  actual = config.services.actual;
in
{
  options.ozzie.lab.actual = {
    enable = lib.mkEnableOption "opinionated actual config";
  };

  config = lib.mkIf cfg.enable {
    services.actual = {
      enable = true;
      group = "actual";
      settings.dataDir = lib.mkDefault "/data/services/actual";
      user = "actual";
    };

    users = {
      groups.actual = { };

      users.actual = {
        group = "actual";
        isSystemUser = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${actual.settings.dataDir} 0700 ${actual.user} ${actual.group}"
      "d ${actual.settings.serverFiles} 0700 ${actual.user} ${actual.group}"
      "d ${actual.settings.userFiles} 0700 ${actual.user} ${actual.group}"
    ];
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/web-apps/actual.nix"
      "pkgs/by-name/ac/actual-server/package.nix"
    ];
  };
}
