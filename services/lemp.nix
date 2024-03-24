{
  config,
  lib,
  pkgs,
  ...
}:
let
  projectHome = "/data/services/lemp";
  projectOwner = "nginx";
  projectGroup = "nginx";
in
{
  networking.firewall.allowedTCPPorts = [ 5173 ];

  environment.systemPackages = with pkgs; [
    nodejs_21
    php83
    php83Packages.composer
  ];

  services = {
    nginx = {
      enable = true;
      group = projectGroup;
      user = projectOwner;

      defaultListen = [
        {
          addr = "127.0.0.1";
          port = 18080;
        }
      ];

      virtualHosts."lemp.localhost" = {
        root = "${projectHome}/php/public";

        extraConfig = ''
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "SAMEORIGIN";
          charset utf-8;
          error_page 404 /index.php;
          index index.php;
          location = /favicon.ico { access_log off; log_not_found off; }
          location = /robots.txt  { access_log off; log_not_found off; }

          location / {
              try_files $uri $uri/ /index.php?$query_string;
          }
        '';

        locations."~ \.php$".extraConfig = ''
          fastcgi_index index.php;
          fastcgi_pass unix:${config.services.phpfpm.pools.lemp.socket};
          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          include ${pkgs.nginx}/conf/fastcgi.conf;
          include ${pkgs.nginx}/conf/fastcgi_params;
        '';
      };
    };

    phpfpm = {
      phpPackage = with pkgs; php83;

      pools.lemp = {
        phpEnv."PATH" = lib.makeBinPath (with pkgs; [ php83 ]);
        user = projectOwner;

        settings = {
          "catch_workers_output" = true;
          "listen.group" = projectGroup;
          "listen.owner" = projectOwner;
          "php_admin_flag[log_errors]" = true;
          "php_admin_value[error_log]" = "stderr";
          "pm" = "dynamic";
          "pm.max_children" = 16;
          "pm.max_requests" = 500;
          "pm.max_spare_servers" = 3;
          "pm.min_spare_servers" = 1;
          "pm.start_servers" = 1;
        };
      };
    };

    mysql = {
      dataDir = "${projectHome}/mysql";
      enable = true;
      group = projectGroup;
      initialDatabases = [ { name = "lemp"; } ];
      package = with pkgs; mariadb;
      user = projectOwner;

      ensureUsers = [
        {
          name = projectOwner;

          ensurePermissions = {
            "*.*" = "ALL PRIVILEGES";
          };
        }
      ];

      settings = {
        mysqld = {
          default_storage_engine = "InnoDB";
          innodb_buffer_pool_size = "256M";
          innodb_file_per_table = "1";
          innodb_log_buffer_size = "8M";
          key_buffer_size = "2G";
          log-error = "${projectHome}/logs/mysql_err.log";
          table_cache = 1600;

          plugin-load-add = [
            "server_audit"
            "ed25519=auth_ed25519"
          ];
        };

        mysqldump = {
          max_allowed_packet = "16M";
          quick = true;
        };
      };
    };
  };
}
