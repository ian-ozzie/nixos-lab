{
  config,
  lib,
  pkgs,
  ...
}:
let
  # TODO: make these options rather than hardcoded
  backupGroup = "users";
  backupHome = "/data/backups/mysql";
  backupTarget = "r2:database-backups";
  backupScript = ''
    find "${backupHome}" -name '*zst' | while read -r line; do
      DB=$(basename "$line" | sed -e's/\.zst$//g')
      TARGET="$DB"-$(date +'%Y-%m-%d').sql.zst

      echo Transferring backup for "$DB" to "$TARGET"

      ${pkgs.rclone}/bin/rclone --s3-no-check-bucket moveto "$line" ${backupTarget}/${config.networking.hostName}/mysql/"$DB"/"$TARGET"
    done
  '';
  backupUser = "mysql-backup";
  cfg = config.ozzie.lab.mysql;
in
{
  options.ozzie.lab.mysql = {
    enable = lib.mkEnableOption "opinionated mysql config";

    backup = {
      enable = lib.mkEnableOption "opinionated mysql-backup config";
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO: Configuration for rclone under backupUser, manually created

    environment.systemPackages =
      with pkgs;
      [
        mysqltuner
      ]
      ++ lib.optional cfg.backup.enable rclone;

    services = {
      mysql = {
        enable = true;
        package = with pkgs; mariadb;

        settings = {
          mysqld = {
            default_storage_engine = lib.mkDefault "InnoDB";
            innodb_buffer_pool_size = lib.mkDefault "256M";
            innodb_file_per_table = lib.mkDefault "1";
            innodb_log_buffer_size = lib.mkDefault "8M";
            max_allowed_packet = lib.mkDefault "32M";
          };

          mysqldump = {
            max_allowed_packet = lib.mkDefault "16M";
            quick = lib.mkDefault true;
          };
        };
      };

      mysqlBackup = lib.mkIf cfg.backup.enable {
        calendar = "05:00:00";
        compressionAlg = "zstd";
        compressionLevel = 9;
        enable = true;
        location = backupHome;
        user = backupUser;
      };
    };

    systemd = lib.mkIf cfg.backup.enable {
      services = {
        mysql-backup = {
          onSuccess = [ "mysql-backup-rclone.service" ];

          serviceConfig = {
            Group = backupGroup;
            UMask = "0027";
          };
        };

        mysql-backup-rclone = {
          after = [ "mysql-backup.service" ];
          script = backupScript;
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Group = backupGroup;
            Type = "oneshot";
            User = backupUser;
            WorkingDirectory = backupHome;
          };
        };
      };

      tmpfiles.rules = [
        "d ${backupHome} 3770 ${backupUser} ${backupGroup} - -"
      ];
    };

    users.users."${backupUser}" = lib.mkIf cfg.backup.enable {
      createHome = false;
      group = backupGroup;
      home = backupHome;
      isSystemUser = true;
    };
  };
}
