{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.ncps;
in
{
  options.ozzie.lab.ncps = {
    enable = lib.mkEnableOption "opinionated ncps config";
  };

  config = lib.mkIf cfg.enable {
    services.ncps = {
      enable = true;

      cache = {
        maxSize = lib.mkDefault "64G";
        storage.local = lib.mkDefault "/cache/services/ncps";

        upstream = {
          publicKeys = lib.mkDefault [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
          urls = lib.mkDefault [ "https://cache.nixos.org" ];
        };
      };
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/networking/ncps.nix"
      "pkgs/by-name/nc/ncps/package.nix"
    ];
  };
}
