{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.gitea-actions-runner;
in
{
  options.ozzie.lab.gitea-actions-runner = {
    enable = lib.mkEnableOption "opinionated gitea-actions-runner config";

    runners = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Runners to set up";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      gitea-actions-runner = {
        package = with pkgs; forgejo-runner;

        instances = {
          # example-runner = lib.mkIf (builtins.elem "example-runner" cfg.runners) {
          #   enable = true;
          #   labels = [ "example:host" ];
          #   name = "example-runner";
          #   tokenFile = "/data/services/gitea-actions-runner/.example-runner.env";
          #   url = "https://git.${config.ozzie.lab.host.shared.domain}";
          #
          #   hostPackages = with pkgs; [
          #     bash
          #     coreutils
          #     curl
          #     gawk
          #     gitMinimal
          #     gnused
          #     nodejs
          #     wget
          #     xc
          #   ];
          # };
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/gitea-actions-runner 0700 root root"
      ];
    };
  };
}
