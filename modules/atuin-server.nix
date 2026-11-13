{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.atuin-server;
in
{
  options.ozzie.lab.atuin-server = {
    enable = lib.mkEnableOption "opinionated atuin-server config";
  };

  config = lib.mkIf cfg.enable {
    services.atuin = {
      database.createLocally = lib.mkDefault false;
      enable = true;
      openRegistration = lib.mkDefault false;
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/misc/atuin.nix"
      "pkgs/by-name/at/atuin/package.nix"
    ];
  };
}
