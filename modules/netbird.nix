{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.netbird;
in
{
  options.ozzie.lab.netbird = {
    enable = lib.mkEnableOption "opinionated netbird config";
    enableUI = lib.mkEnableOption "opinionated netbird UI config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      netbird = {
        package = with pkgs; netbird;

        clients.personal = {
          dir.state = "/data/services/netbird";
          hardened = false;
          interface = "wt0";
          name = "netbird";
          port = 51820;
        };

        ui = {
          enable = cfg.enableUI;
          package = with pkgs; netbird-ui;
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/netbird 0700 root root"
      ];
    };
  };
}
