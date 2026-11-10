{
  config,
  lib,
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
}
