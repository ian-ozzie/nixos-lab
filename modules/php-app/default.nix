{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.php-app;

  appModule = _: {
    options = {
      phpPackage = lib.mkOption {
        default = cfg.package;
        description = "php package to use for the pool";
        type = lib.types.package;
      };
    };
  };
in
{
  imports = [
    ./processes.nix
    ./web.nix
  ];

  options.ozzie.lab.php-app = {
    enable = lib.mkEnableOption "opinionated php-app config";

    apps = lib.mkOption {
      default = { };
      description = "apps to set up";
      type = lib.types.attrsOf (lib.types.submodule appModule);
    };

    package = lib.mkOption {
      default = pkgs.php;
      type = lib.types.package;
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/web-servers/phpfpm"
      "nixos/modules/services/web-servers/caddy"
      "pkgs/development/interpreters/php"
    ];
  };
}
