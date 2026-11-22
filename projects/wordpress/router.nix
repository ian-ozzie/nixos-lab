{
  localApp,
  project,
  projectNetwork,
  ...
}:
{
  lib,
  memberName,
  ...
}:
let
  authorizationPolicy = project.authorizationPolicy or null;
  host = project.hostName;
in
{
  ozzie.lab.caddy = {
    enable = true;
    security.enable = lib.mkIf (authorizationPolicy != null) true;

    sites.${host} = {
      domain = lib.mkIf (project ? domain) project.domain;
      listenAddresses = [ (projectNetwork.address "frontend" memberName) ];

      extraConfig = lib.mkBefore (
        lib.optionalString (authorizationPolicy != null) ''
          route {
            @wordpressAdmin {
              path /wp-login.php /wp-login.php/* /wp-admin /wp-admin/*
              not path /wp-admin/admin-ajax.php /wp-admin/admin-post.php /wp-admin/load-scripts.php /wp-admin/load-styles.php
              not path_regexp ^/wp-admin/(css|images|js)/.*\.(css|gif|ico|js|png|svg|webp|woff2?)$
            }

            authorize @wordpressAdmin with ${builtins.toJSON authorizationPolicy}
          }
        ''
      );

      proxyConfig = lib.optionalString (!localApp) ''
        header_up Host {http.request.host}

        transport http {
          tls_server_name ${host}
        }
      '';

      upstreams = lib.optionals (!localApp) (
        map (endpoint: "https://${endpoint}") (projectNetwork.endpoints "backend" project.roles.app 443)
      );
    };
  };
}
