{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.atuin-daemon;
in
{
  options.ozzie.lab.atuin-daemon = {
    enable = lib.mkEnableOption "opinionated atuin-daemon config";
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      user = {
        services.atuin-daemon = {
          serviceConfig.ExecStart = "${pkgs.atuin}/bin/atuin daemon";
          unitConfig.Description = "Atuin Magical Shell History Daemon";
        };

        sockets.atuin-daemon = {
          unitConfig.Description = "Atuin Magical Shell History Daemon";
          wantedBy = [ "sockets.target" ];

          socketConfig = {
            Accept = false;
            ListenStream = "%t/atuin.sock";
            SocketMode = "0600";
          };
        };
      };
    };
  };
}
