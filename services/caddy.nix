{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.caddy;
in
{
  options.ozzie.lab.caddy = {
    enable = lib.mkEnableOption "opinionated caddy config";
    package = lib.mkPackageOption pkgs "caddy" { };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      package = cfg.package;
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/caddy 0700 caddy caddy"
        "d /var/log/caddy 0755 caddy caddy"
      ];
    };
  };
}
