{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.php-fpm-app;
  pools = lib.groupBy (app: app.pool) (lib.attrValues cfg.apps);

  appModule = { name, ... }: {
    options = {
      root = lib.mkOption {
        description = "root to serve the php app from";
        type = lib.types.strMatching "/.*";
      };

      phpPackage = lib.mkOption {
        default = pkgs.php;
        description = "php package to use for the pool";
        type = lib.types.package;
      };

      pool = lib.mkOption {
        default = name;
        description = "pool to use";
        type = lib.types.strMatching "[A-Za-z_][A-Za-z0-9_-]*";
      };

      listenAddress = lib.mkOption {
        default = "127.0.0.1";
        description = "addresses to bind the app to";
        type = lib.types.str;
      };

      port = lib.mkOption {
        description = "port to bind the app on";
        type = lib.types.port;
      };
    };
  };
in
{
  options.ozzie.lab.php-fpm-app = {
    enable = lib.mkEnableOption "opinionated php-fpm-app config";

    apps = lib.mkOption {
      default = { };
      description = "apps to set up";
      type = lib.types.attrsOf (lib.types.submodule appModule);
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.mapAttrsToList (pool: apps: {
      assertion = lib.length (lib.unique (map (app: toString app.phpPackage) apps)) == 1;
      message = "ozzie.lab.php-fpm-app: apps sharing pool '${pool}' must use the same phpPackage";
    }) pools;

    ozzie.lab.caddy = {
      enable = true;

      sites = lib.mapAttrs' (name: app: {
        name = "php-fpm-app-${name}";

        value = {
          domain = null;
          hostname = "http://:${toString app.port}";
          listenAddresses = [ app.listenAddress ];

          extraConfig = ''
            root * ${builtins.toJSON app.root}
            header X-Frame-Options SAMEORIGIN
            header X-Content-Type-Options nosniff
            php_fastcgi unix/${config.services.phpfpm.pools.${app.pool}.socket}
            file_server
          '';
        };
      }) cfg.apps;
    };

    services.phpfpm.pools = lib.mapAttrs (_: apps: {
      inherit (lib.head apps) phpPackage;

      group = "caddy";
      user = "caddy";

      settings = lib.mapAttrs (_: lib.mkDefault) {
        "catch_workers_output" = true;
        "listen.group" = "caddy";
        "listen.mode" = "0600";
        "listen.owner" = "caddy";
        "php_admin_flag[log_errors]" = true;
        "php_admin_value[error_log]" = "stderr";
        "pm" = "dynamic";
        "pm.max_children" = 4;
        "pm.max_requests" = 500;
        "pm.max_spare_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.start_servers" = 1;
      };
    }) pools;
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/web-servers/phpfpm"
      "nixos/modules/services/web-servers/caddy"
      "pkgs/development/interpreters/php"
    ];
  };
}
