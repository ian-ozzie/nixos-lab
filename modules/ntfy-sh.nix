{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.ntfy-sh;
in
{
  options.ozzie.lab.ntfy-sh = {
    enable = lib.mkEnableOption "opinionated ntfy-sh config";
  };

  config = lib.mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      package = with pkgs; ntfy-sh;

      settings = {
        template-dir = lib.mkDefault "/data/services/ntfy-sh/templates";
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/ntfy-sh 0700 ntfy-sh ntfy-sh"
        "d /data/services/ntfy-sh/templates 0700 ntfy-sh ntfy-sh"
      ];
    };
  };
}
