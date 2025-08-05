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
          hardened = false;
          interface = "wt0";
          name = "netbird";
          port = 51820;

          dir = {
            baseName = "netbird";
            state = "/data/services/netbird";
          };
        };

        ui = lib.mkIf cfg.enableUI {
          enable = true;
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
