{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.beszel-hub;
  hub = config.services.beszel.hub;
in
{
  options.ozzie.lab.beszel-hub = {
    enable = lib.mkEnableOption "opinionated beszel hub config";
  };

  config = lib.mkIf cfg.enable {
    services.beszel.hub = {
      dataDir = lib.mkDefault "/data/services/beszel-hub";
      enable = true;
      environment.DISABLE_SSH = lib.mkDefault "true";
    };

    users = {
      groups.beszel-hub = { };

      users.beszel-hub = {
        group = "beszel-hub";
        isSystemUser = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${hub.dataDir} 0700 beszel-hub beszel-hub"
    ];
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/monitoring/beszel-hub.nix"
      "pkgs/by-name/be/beszel/package.nix"
    ];
  };
}
