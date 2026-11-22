{
  localApp,
  localDatabase,
  project,
  projectName,
  projectNetwork,
  ...
}:
{ lib, ... }:
let
  endpoint = name: settings: {
    name = "${projectName}-${name}";

    value = {
      inherit name;

      group = projectName;
    }
    // settings;
  };

  tcpEndpoint =
    role: port:
    endpoint "${role}-${project.roles.${role}}" {
      conditions = [ "[CONNECTED] == true" ];
      url = "tcp://${projectNetwork.endpoint "backend" project.roles.${role} port}";
    };

  httpsEndpoint =
    name: path: status:
    endpoint name {
      client.ignore-redirect = true;
      url = "https://${project.hostName}${path}";

      conditions = [
        "[STATUS] == ${toString status}"
        "[CERTIFICATE_EXPIRATION] > 168h"
      ];
    };
in
{
  ozzie.lab.gatus = {
    enable = true;

    endpoints = lib.listToAttrs (
      lib.optional (!localDatabase) (tcpEndpoint "mysql" 3306)
      ++ lib.optional (!localApp) (tcpEndpoint "app" 443)
      ++ [ (httpsEndpoint "router" "/" 200) ]
      ++ lib.optional ((project.authorizationPolicy or null) != null) (
        httpsEndpoint "sso" "/wp-login.php" 302
      )
    );
  };
}
