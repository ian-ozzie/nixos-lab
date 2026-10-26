{
  config,
  lib,
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
}
