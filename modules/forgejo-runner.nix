{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.forgejo-runner;
in
{
  options.ozzie.lab.forgejo-runner = {
    enable = lib.mkEnableOption "opinionated forgejo-runner config";

    runners = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Runners to set up";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      forgejo-runner = {
        package = with pkgs; forgejo-runner;

        instances = {
          # example-runner = lib.mkIf (builtins.elem "example-runner" cfg.runners) {
          #   enable = true;
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
          #
          #   secrets.server.connections.default.token_url =
          #     "/data/services/forgejo-runner/.example-runner.token";
          #
          #   settings = {
          #     runner.labels = [ "example:host" ];
          #
          #     server.connections.default = {
          #       url = "https://git.example.com";
          #       uuid = "<runner-uuid>";
          #     };
          #   };
          # };
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/forgejo-runner 0700 root root"
      ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/continuous-integration/forgejo-runner.nix"
      "pkgs/by-name/fo/forgejo-runner/package.nix"
    ];
  };
}
