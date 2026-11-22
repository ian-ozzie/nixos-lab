{ config, lib, ... }:
let
  apps = lib.filterAttrs (_: app: app.fpm.enable) cfg.apps;
  caddy = config.services.caddy;
  cfg = config.ozzie.lab.php-app;
  pools = lib.groupBy (app: app.pool) (lib.attrValues apps);
in
{
  options.ozzie.lab.php-app.apps = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }: {
          options = {
            fpm = {
              enable = lib.mkEnableOption "opinionated php-fpm config";

              site = lib.mkOption {
                type = lib.types.str;
              };
            };

            caddyConfig = lib.mkOption {
              default = null;
              type = lib.types.nullOr (lib.types.either lib.types.lines (lib.types.functionTo lib.types.lines));
            };
            extraConfig = lib.mkOption {
              default = "";
              type = lib.types.lines;
            };

            pool = lib.mkOption {
              default = name;
              description = "pool to use";
              type = lib.types.strMatching "[A-Za-z_][A-Za-z0-9_-]*";
            };

            root = lib.mkOption {
              description = "root to serve the php app from";
              type = lib.types.strMatching "/.*";
            };
          };
        }
      )
    );
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.mapAttrsToList (pool: apps: {
      assertion = lib.length (lib.unique (map (app: toString app.phpPackage) apps)) == 1;
      message = "ozzie.lab.php-app: apps sharing pool '${pool}' must use the same phpPackage";
    }) pools;

    ozzie.lab.caddy = {
      enable = lib.mkIf (apps != { }) true;

      sites = lib.mkMerge (
        lib.mapAttrsToList (_: app: {
          ${app.fpm.site}.extraConfig =
            let
              socket = config.services.phpfpm.pools.${app.pool}.socket;
            in
            if app.caddyConfig == null then
              ''
                route {
                  root * ${builtins.toJSON app.root}
                  header X-Frame-Options SAMEORIGIN
                  header X-Content-Type-Options nosniff
                  ${app.extraConfig}
                  php_fastcgi unix/${socket}
                  file_server
                }
              ''
            else if lib.isFunction app.caddyConfig then
              app.caddyConfig {
                inherit (app) root;
                inherit socket;
              }
            else
              app.caddyConfig;
        }) apps
      );
    };

    services.phpfpm.pools = lib.mapAttrs (_: apps: {
      inherit (lib.head apps) phpPackage;
      inherit (caddy) group user;

      settings = lib.mapAttrs (_: lib.mkDefault) {
        "catch_workers_output" = true;
        "listen.group" = caddy.group;
        "listen.mode" = "0600";
        "listen.owner" = caddy.user;
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
}
