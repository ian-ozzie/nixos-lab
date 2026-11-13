{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.komga;
in
{
  options.ozzie.lab.komga = {
    enable = lib.mkEnableOption "opinionated komga config";
  };

  config = lib.mkIf cfg.enable {
    services.komga = {
      enable = true;
      stateDir = lib.mkDefault "/data/services/komga";
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/web-apps/komga.nix"
      "pkgs/by-name/ko/komga/package.nix"
    ];
  };
}
