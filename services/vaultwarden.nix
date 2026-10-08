{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.vaultwarden;
in
{
  options.ozzie.lab.vaultwarden = {
    enable = lib.mkEnableOption "opinionated vaultwarden config";
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      dbBackend = "mysql";
      enable = true;
      package = with pkgs; vaultwarden;

      config = {
        ROCKET_ADDRESS = lib.mkDefault "127.0.0.1";
        ROCKET_LOG = lib.mkDefault "critical";
        ROCKET_PORT = lib.mkDefault 8222;

        SIGNUPS_ALLOWED = lib.mkDefault false;
      };
    };
  };
}
