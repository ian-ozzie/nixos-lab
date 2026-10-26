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
          environment.ATUIN_DAEMON__SYSTEMD_SOCKET = "true";
          requires = [ "atuin-daemon.socket" ];
          unitConfig.Description = "Atuin Magical Shell History Daemon";

          serviceConfig = {
            ExecStart = "${pkgs.atuin}/bin/atuin daemon start";
            Restart = "on-failure";
          };
        };

        sockets.atuin-daemon = {
          unitConfig.Description = "Atuin Magical Shell History Daemon";
          wantedBy = [ "sockets.target" ];

          socketConfig = {
            ListenStream = "%t/atuin.sock";
            RemoveOnStop = true;
            SocketMode = "0600";
          };
        };
      };
    };
  };
}
