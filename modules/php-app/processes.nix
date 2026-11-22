{ config, lib, ... }:
let
  cfg = config.ozzie.lab.php-app;
  caddy = config.services.caddy;
  hasCommands = lib.any (app: app.services != { } || app.schedules != { }) (lib.attrValues cfg.apps);

  commandModule = scheduled: {
    options = {
      after = lib.mkOption {
        default = [ "network.target" ];
        type = lib.types.listOf lib.types.str;
      };

      command = lib.mkOption {
        type = lib.types.str;
      };

      environment = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.str;
      };

      path = lib.mkOption {
        default = [ ];
        type = lib.types.listOf (lib.types.either lib.types.package lib.types.str);
      };

      serviceConfig = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.anything;
      };
    }
    // lib.optionalAttrs scheduled {
      timerConfig = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;

        default = {
          OnBootSec = "1min";
          OnUnitActiveSec = "1min";
          Persistent = true;
        };
      };
    };
  };

  commandServices =
    scheduled:
    lib.concatMapAttrs (
      name: app:
      lib.mapAttrs' (
        commandName: command:
        lib.nameValuePair "php-app-${name}-${commandName}" {
          inherit (command) after environment path;

          wantedBy = lib.optional (!scheduled) "multi-user.target";

          serviceConfig = lib.mkMerge [
            (lib.mapAttrs (_: lib.mkDefault) (
              {
                ExecStart = command.command;
                Group = caddy.group;
                StandardError = "journal";
                StandardOutput = "journal";
                Type = if scheduled then "oneshot" else "simple";
                User = caddy.user;
                WorkingDirectory = app.workingDirectory;
              }
              // lib.optionalAttrs (!scheduled) {
                Restart = "on-failure";
                RestartSec = 5;
              }
            ))
            command.serviceConfig
          ];
        }
      ) (if scheduled then app.schedules else app.services)
    ) cfg.apps;
in
{
  options.ozzie.lab.php-app.apps = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          workingDirectory = lib.mkOption {
            default = null;
            type = lib.types.nullOr (lib.types.strMatching "/.*");
          };

          services = lib.mkOption {
            default = { };
            type = lib.types.attrsOf (lib.types.submodule (commandModule false));
          };

          schedules = lib.mkOption {
            default = { };
            type = lib.types.attrsOf (lib.types.submodule (commandModule true));
          };

        };
      }
    );
  };

  config = lib.mkIf cfg.enable {
    users = lib.mkIf (hasCommands && !caddy.enable) {
      users.caddy = lib.mkIf (caddy.user == "caddy") {
        inherit (caddy) group;

        isSystemUser = true;
        uid = config.ids.uids.caddy;
      };

      groups.caddy = lib.mkIf (caddy.group == "caddy") {
        gid = config.ids.gids.caddy;
      };
    };

    assertions =
      lib.mapAttrsToList (name: app: {
        assertion = (app.services == { } && app.schedules == { }) || app.workingDirectory != null;
        message = "ozzie.lab.php-app: app '${name}' requires workingDirectory when services or schedules are configured";
      }) cfg.apps
      ++ lib.mapAttrsToList (name: app: {
        assertion = lib.intersectLists (lib.attrNames app.services) (lib.attrNames app.schedules) == [ ];
        message = "ozzie.lab.php-app: app '${name}' cannot use the same name for a service and a schedule";
      }) cfg.apps;

    systemd.services = lib.mkMerge [
      (commandServices false)
      (commandServices true)
    ];

    systemd.timers = lib.concatMapAttrs (
      name: app:
      lib.mapAttrs' (
        scheduleName: schedule:
        lib.nameValuePair "php-app-${name}-${scheduleName}" {
          inherit (schedule) timerConfig;

          wantedBy = [ "timers.target" ];
        }
      ) app.schedules
    ) cfg.apps;
  };
}
