{
  config,
  lib,
  pkgs,
  ...
}:
let
  backupDatabases = lib.attrNames (lib.filterAttrs (_: database: database.backup) cfg.databases);
  cfg = config.ozzie.lab.postgresql;
  databaseNames = lib.attrNames cfg.databases;
  identifier = "[A-Za-z_][A-Za-z0-9_]{0,62}";
  passwordDatabases = lib.filterAttrs (_: database: database.passwordFile != null) cfg.databases;
  socketDatabases = lib.filterAttrs (_: database: database.passwordFile == null) cfg.databases;

  backupScript = ''
    ${lib.optionalString (cfg.backup.rcloneConfigFile != null) ''
      export RCLONE_CONFIG="$CREDENTIALS_DIRECTORY/rclone.conf"
    ''}

    failed=0
    for database in ${lib.escapeShellArgs backupDatabases}; do
      dump=${lib.escapeShellArg (toString cfg.backup.location)}/"$database.sql.zstd"
      test -e "$dump" || continue

      timestamp=$(date -u -r "$dump" +'%Y-%m-%dT%H-%M-%S.%NZ')
      relative="$database/$timestamp.sql.zst"
      destination=${lib.escapeShellArg "${cfg.backup.target}/${config.networking.hostName}/postgresql"}/"$relative"

      echo Transferring backup "$relative"

      if ! ${pkgs.rclone}/bin/rclone --s3-no-check-bucket moveto "$dump" "$destination"; then
        failed=1
      fi
    done

    exit "$failed"
  '';

  defaultHosts = [
    "127.0.0.1/32"
    "::1/128"
  ];

  remoteHosts = lib.filter (host: !lib.elem host defaultHosts) (
    lib.concatMap (database: database.hosts) (lib.attrValues passwordDatabases)
  );
in
{
  options.ozzie.lab.postgresql = {
    enable = lib.mkEnableOption "opinionated postgresql config";

    backup = {
      enable = lib.mkEnableOption "opinionated postgresql-backup config";

      group = lib.mkOption {
        default = "nogroup";
        type = lib.types.str;
      };

      location = lib.mkOption {
        default = "/data/backups/postgresql";
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
    };

    databases = lib.mkOption {
      default = { };

      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }: {
            options = {
              backup = lib.mkOption {
                default = true;
                type = lib.types.bool;
              };

              user = lib.mkOption {
                default = name;
                type = lib.types.strMatching identifier;
              };

              hosts = lib.mkOption {
                default = defaultHosts;
                type = lib.types.nonEmptyListOf (lib.types.strMatching "[A-Za-z0-9:][A-Za-z0-9.:/-]*");
              };

              passwordFile = lib.mkOption {
                default = null;
                type = lib.types.nullOr lib.types.str;
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (name: builtins.match identifier name != null) databaseNames;
        message = "ozzie.lab.postgresql.databases names must contain 1–63 ASCII letters, digits, or underscores and start with a letter or underscore";
      }
      {
        assertion = lib.all (database: database.hosts == defaultHosts) (lib.attrValues socketDatabases);
        message = "ozzie.lab.postgresql.databases without a passwordFile use peer authentication and must only allow loopback hosts";
      }
    ];

    environment.systemPackages =
      with pkgs;
      [
        pg_activity
      ]
      ++ lib.optional cfg.backup.enable rclone;

    services = {
      postgresql = {
        enable = true;
        enableTCPIP = lib.mkDefault (remoteHosts != [ ]);
        ensureDatabases = databaseNames;

        authentication = lib.concatStrings (
          lib.mapAttrsToList (
            name: database:
            lib.concatMapStrings (host: ''
              host "${name}" "${database.user}" ${host} scram-sha-256
            '') database.hosts
          ) passwordDatabases
        );

        ensureUsers = map (user: { name = user; }) (
          lib.unique (lib.mapAttrsToList (_: database: database.user) cfg.databases)
        );

        settings = {
          shared_buffers = lib.mkDefault "256MB";
        };
      };

      postgresqlBackup = lib.mkIf cfg.backup.enable {
        backupAll = false;
        compression = "zstd";
        compressionLevel = 9;
        databases = backupDatabases;
        enable = true;
        location = cfg.backup.location;
        startAt = "05:00:00";
      };
    };

    systemd = {
      services = lib.mkMerge [
        {
          postgresql-accounts = lib.mkIf (cfg.databases != { }) {
            after = [ "postgresql-setup.service" ];
            partOf = [ "postgresql.service" ];
            path = [ config.services.postgresql.finalPackage ];
            requires = [ "postgresql-setup.service" ];
            wantedBy = [ "multi-user.target" ];
            environment.PGPORT = toString config.services.postgresql.settings.port;

            script = lib.concatStrings (
              lib.mapAttrsToList (name: database: ''
                psql --no-psqlrc -v ON_ERROR_STOP=1 <<'SQL'
                ALTER DATABASE "${name}" OWNER TO "${database.user}";
                SQL
              '') cfg.databases
              ++ lib.mapAttrsToList (name: database: ''
                password=$(< "$CREDENTIALS_DIRECTORY/${name}")
                test -n "$password"

                psql --no-psqlrc -v ON_ERROR_STOP=1 -v password="$password" <<'SQL'
                ALTER ROLE "${database.user}" WITH LOGIN PASSWORD :'password';
                SQL

                unset password
              '') passwordDatabases
            );

            serviceConfig = {
              RemainAfterExit = true;
              Type = "oneshot";
              User = "postgres";

              LoadCredential = lib.mapAttrsToList (
                name: database: "${name}:${database.passwordFile}"
              ) passwordDatabases;
            };
          };

          postgresql-backup-rclone = lib.mkIf cfg.backup.enable {
            after = map (database: "postgresqlBackup-${database}.service") backupDatabases;
            path = [ pkgs.coreutils ];
            script = lib.mkDefault backupScript;

            serviceConfig = {
              Group = cfg.backup.group;
              Type = "oneshot";
              UMask = "0077";
              User = "postgres";
              WorkingDirectory = cfg.backup.location;

              LoadCredential = lib.mkIf (cfg.backup.rcloneConfigFile != null) [
                "rclone.conf:${cfg.backup.rcloneConfigFile}"
              ];
            };
          };
        }

        (lib.mkIf cfg.backup.enable (
          lib.genAttrs (map (database: "postgresqlBackup-${database}") backupDatabases) (_: {
            onSuccess = [ "postgresql-backup-rclone.service" ];

            serviceConfig = {
              Group = cfg.backup.group;
              UMask = "0077";
            };
          })
        ))
      ];
    };

    users = lib.mkIf cfg.backup.enable {
      groups.${cfg.backup.group} = { };
    };
  };
}
