{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.atuin;
in
{
  options.ozzie.lab.atuin = {
    enable = lib.mkEnableOption "opinionated atuin server config";
  };

  config = lib.mkIf cfg.enable {
    services.atuin = {
      database.createLocally = lib.mkDefault false;
      enable = true;
      openRegistration = lib.mkDefault false;
      package = with pkgs; atuin;
    };
  };
}
