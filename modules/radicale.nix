{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.radicale;
in
{
  options.ozzie.lab.radicale = {
    enable = lib.mkEnableOption "opinionated radicale config";
  };

  config = lib.mkIf cfg.enable {
    services.radicale = {
      enable = true;
      package = with pkgs; radicale;

      settings = {
        storage.filesystem_folder = lib.mkDefault "/data/services/radicale/collections";

        auth = {
          htpasswd_encryption = lib.mkDefault "autodetect";
          htpasswd_filename = lib.mkDefault "/data/services/radicale/users";
          type = lib.mkDefault "htpasswd";
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/radicale 0700 radicale radicale"
        "d /data/services/radicale/collections 0700 radicale radicale"
        "f /data/services/radicale/users 0700 radicale radicale"
      ];
    };
  };
}
