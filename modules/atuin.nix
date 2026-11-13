{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.atuin;
in
{
  options.ozzie.lab.atuin = {
    enable = lib.mkEnableOption "opinionated atuin config";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.atuin-daemon.environment.ATUIN_CONFIG_DIR = "/etc/atuin";

    programs.atuin = {
      daemon.enable = true;
      enable = true;

      flags = [
        "--disable-ai"
        "--disable-up-arrow"
      ];

      settings = {
        auto_sync = true;
        dialect = "uk";
        enter_accept = true;
        exit_mode = "return-original";
        filter_mode = "host";
        inline_height = 20;
        search_mode = "fulltext";
        show_help = false;
        show_preview = true;
        show_tabs = false;
        style = "compact";
        update_check = false;

        daemon = {
          enabled = true;
          autostart = false;
          socket_path = "$XDG_RUNTIME_DIR/atuin/atuin.sock";
          systemd_socket = true;
        };
      };
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/programs/atuin.nix"
      "pkgs/by-name/at/atuin/package.nix"
    ];
  };
}
