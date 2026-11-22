{
  database,
  localApp,
  localDatabase,
  phpRuntime,
  project,
  projectName,
  projectNetwork,
  ...
}:
{
  config,
  lib,
  memberName,
  pkgs,
  ...
}:
let
  backendAddress = projectNetwork.address "backend" memberName;
  databaseUser = if localDatabase then user else database;
  group = config.services.caddy.group;
  host = project.hostName;
  plugins = "${siteData}/plugins";
  runtimePassword = "/run/phpfpm/${database}-mysql-password";
  siteData = "/data/sites/${host}";
  themes = "${siteData}/themes";
  uploads = "${siteData}/uploads";
  user = config.services.caddy.user;

  backendClients = lib.unique (
    projectNetwork.addresses "backend" project.roles.router
    ++ projectNetwork.addresses "backend" (project.roles.monitor or [ ])
  );

  databaseHost =
    if localDatabase then
      "localhost:${config.services.mysql.settings.mysqld.socket or "/run/mysqld/mysqld.sock"}"
    else
      "${projectNetwork.urlAddress (projectNetwork.address "backend" project.roles.mysql)}:3306";

  wordpress = pkgs.runCommand "wordpress-${projectName}" { } ''
    cp -r ${pkgs.wordpress}/share/wordpress "$out"
    chmod -R u+w "$out"
    cp ${wpConfig} "$out/wp-config.php"
    rm -f "$out/wp-config-sample.php" "$out/readme.html"
    rm -rf "$out/wp-content/plugins" "$out/wp-content/themes"
    ln -s ${lib.escapeShellArg uploads} "$out/wp-content/uploads"
    ln -s ${lib.escapeShellArg plugins} "$out/wp-content/plugins"
    ln -s ${lib.escapeShellArg themes} "$out/wp-content/themes"
  '';

  wpConfig = pkgs.writeText "wp-config.php" ''
    <?php declare(strict_types = 1);

    define('DB_NAME', ${builtins.toJSON database});
    define('DB_USER', ${builtins.toJSON databaseUser});
    define('DB_PASSWORD', ${
      if localDatabase then
        "''"
      else
        "rtrim(file_get_contents(${builtins.toJSON runtimePassword}), \"\\n\")"
    });
    define('DB_HOST', ${builtins.toJSON databaseHost});
    define('DB_CHARSET', "utf8mb4");
    define('DB_COLLATE', "");
    define('DISALLOW_FILE_MODS', true);
    $table_prefix = 'wp_';
    if (!defined('ABSPATH')) {
      define('ABSPATH', __DIR__ . '/');
    }

    $site_config = ${builtins.toJSON "${siteData}/wp-config.php"};
    if (is_file($site_config)) {
      require $site_config;
    }

    require_once ABSPATH . 'wp-settings.php';
  '';
in
{
  imports = [ phpRuntime ];

  ozzie.lab = {
    caddy = {
      enable = true;

      sites.${host} = lib.mkIf (!localApp) {
        domain = lib.mkIf (project ? domain) project.domain;
        listenAddresses = [ backendAddress ];
      };
    };

    php-app.apps.${projectName} = {
      root = "${wordpress}";

      fpm = {
        enable = true;
        site = host;
      };

      caddyConfig = { root, socket }: ''
        route {
          root * ${builtins.toJSON root}
          respond /wp-config.php 404

          @uploadedPHP path_regexp (?i)^/wp-content/uploads/.*\.php(?:/|$)
          respond @uploadedPHP 404

          file_server /wp-content/uploads/*
          php_fastcgi unix/${socket}
          file_server
        }
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "d ${uploads} 0755 ${user} ${group} -"
    "d ${plugins} 0755 ${user} ${group} -"
    "d ${themes} 0755 ${user} ${group} -"
    "L ${themes}/twentytwentyfive - - - - ${pkgs.wordpressPackages.themes.twentytwentyfive}"
  ];

  systemd.services."phpfpm-${projectName}" = lib.mkMerge [
    (lib.mkIf localDatabase {
      after = [ "mysql.service" ];
      requires = [ "mysql.service" ];
    })

    (lib.mkIf (!localDatabase) {
      serviceConfig.LoadCredential = [ "mysql-password:${project.mysql.passwordFile or ""}" ];

      preStart = ''
        ${pkgs.coreutils}/bin/install -m 0400 -o ${lib.escapeShellArg user} \
          "$CREDENTIALS_DIRECTORY/mysql-password" ${lib.escapeShellArg runtimePassword}
      '';
    })
  ];

  services.firewalld.zones.nixos-fw-default.rules = lib.mkIf (!localApp) (
    map (client: {
      "@family" = projectNetwork.addressFamily client;
      accept = "";
      destination."@address" = backendAddress;
      source."@address" = client;

      port = {
        "@port" = "443";
        "@protocol" = "tcp";
      };
    }) backendClients
  );
}
