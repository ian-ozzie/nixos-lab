{
  config,
  lib,
  options,
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
        instances = {
          # Rough example that covers the base packages, sops handling secrets
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
          #     jq
          #     nodejs
          #     openssh
          #     wget
          #     xc
          #   ];
          #
          #   secrets.server.connections = {
          #     default.token_url = config.sops.secrets."runners/example-runner/default/token".path;
          #   };
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
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/continuous-integration/forgejo-runner.nix"
      "pkgs/by-name/fo/forgejo-runner/package.nix"
    ];
  };
}
