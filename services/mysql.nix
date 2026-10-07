{
  config,
  lib,
  pkgs,
  ...
}:
let
  backupDatabases = lib.attrNames (lib.filterAttrs (_: database: database.backup) cfg.databases);
  cfg = config.ozzie.lab.mysql;
  databaseNames = lib.attrNames cfg.databases;

  backupScript = ''
    shopt -s nullglob
    ${lib.optionalString (cfg.backup.rcloneConfigFile != null) ''
      export RCLONE_CONFIG="$CREDENTIALS_DIRECTORY/rclone.conf"
    ''}

    failed=0
    for dump in ${lib.escapeShellArg (toString cfg.backup.location)}/*.zst; do
      database=$(basename "$dump" .zst)
      timestamp=$(date -u -r "$dump" +'%Y-%m-%dT%H-%M-%S.%NZ')
      relative="$database/$timestamp.sql.zst"
      destination=${lib.escapeShellArg "${cfg.backup.target}/${config.networking.hostName}/mysql"}/"$relative"

      echo Transferring backup "$relative"

      if ! ${pkgs.rclone}/bin/rclone --s3-no-check-bucket moveto "$dump" "$destination"; then
        failed=1
      fi
    done

    exit "$failed"
  '';
in
{
  options.ozzie.lab.mysql = {
    enable = lib.mkEnableOption "opinionated mysql config";

    backup = {
      enable = lib.mkEnableOption "opinionated mysql-backup config";

      group = lib.mkOption {
        default = "nogroup";
        type = lib.types.str;
      };

      location = lib.mkOption {
        default = "/data/backups/mysql";
        type = lib.types.path;
      };

      rcloneConfigFile = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.str;
      };

      target = lib.mkOption {
        default = "r2:database-backups";
        type = lib.types.str;
      };

      user = lib.mkOption {
        default = "mysqlbackup";
        type = lib.types.str;
      };
    };

    databases = lib.mkOption {
      default = { };

      type = lib.types.attrsOf (
        lib.types.submodule {
          options.backup = lib.mkOption {
            default = true;
            type = lib.types.bool;
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (name: builtins.match "[A-Za-z_][A-Za-z0-9_]{0,63}" name != null) databaseNames;
        message = "ozzie.lab.mysql.databases names must contain 1–64 ASCII letters, digits, or underscores and start with a letter or underscore";
      }
    ];

    environment.systemPackages =
      with pkgs;
      [
        mysqltuner
      ]
      ++ lib.optional cfg.backup.enable rclone;

    services = {
      mysql = {
        enable = true;
        ensureDatabases = databaseNames;
        package = with pkgs; mariadb;

        settings = {
          mysqld = {
            innodb_buffer_pool_size = lib.mkDefault "256M";
            max_allowed_packet = lib.mkDefault "32M";
          };

          mysqldump = {
            max_allowed_packet = lib.mkDefault "32M";
          };
        };
      };

      mysqlBackup = lib.mkIf cfg.backup.enable {
        calendar = "05:00:00";
        compressionAlg = "zstd";
        compressionLevel = 9;
        databases = backupDatabases;
        enable = true;
        location = cfg.backup.location;
        singleTransaction = true;
        user = cfg.backup.user;
      };
    };

    systemd = lib.mkIf cfg.backup.enable {
      services = {
        mysql-backup = {
          onSuccess = [ "mysql-backup-rclone.service" ];

          serviceConfig = {
            Group = cfg.backup.group;
            UMask = "0077";
          };
        };

        mysql-backup-rclone = {
          after = [ "mysql-backup.service" ];
          path = [ pkgs.coreutils ];
          script = lib.mkDefault backupScript;

          serviceConfig = {
            Group = cfg.backup.group;
            Type = "oneshot";
            UMask = "0077";
            User = cfg.backup.user;
            WorkingDirectory = cfg.backup.location;

            LoadCredential = lib.mkIf (cfg.backup.rcloneConfigFile != null) [
              "rclone.conf:${cfg.backup.rcloneConfigFile}"
            ];
          };
        };
      };
    };

    users = lib.mkIf cfg.backup.enable {
      groups.${cfg.backup.group} = { };

      users."${cfg.backup.user}" = lib.mkIf (cfg.backup.user != "mysqlbackup") {
        createHome = false;
        group = cfg.backup.group;
        home = cfg.backup.location;
        isSystemUser = true;
      };
    };
  };
}
