{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    mysql = {
      enable = true;
      package = with pkgs; mariadb;
    };

    nginx = {
      defaultListen = [ { addr = "127.0.0.1"; } ];
      enable = true;

      virtualHosts."lemp.localhost" = {
        root = "/data/lemp/public";

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
          fastcgi_buffer_size 32k;
          fastcgi_buffers 16 16k;
          fastcgi_index index.php;
          fastcgi_param PATH_INFO $fastcgi_path_info;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          fastcgi_pass unix:${config.services.phpfpm.pools.lemp.socket};
          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          include fastcgi_params;
        '';
      };
    };

    phpfpm.pools.lemp = {
      phpEnv."PATH" = lib.makeBinPath (with pkgs; [ php ]);

      settings = {
        "catch_workers_output" = true;
        "listen.group" = config.services.nginx.group;
        "listen.owner" = config.services.nginx.user;
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
}
