{
  localApp,
  ports,
  project,
  projectName,
  projectNetwork,
  ...
}:
{
  lib,
  ...
}:
let
  endpoint = name: settings: {
    name = "${projectName}-${name}";

    value = {
      inherit name;

      group = projectName;
    }
    // settings;
  };
in
{
  ozzie.lab.gatus = {
    enable = true;

    endpoints = lib.listToAttrs (
      lib.optionals (!localApp) (
        lib.concatMap (
          member:
          map (
            port:
            endpoint "app-${member}-${toString port}" {
              conditions = [ "[CONNECTED] == true" ];
              url = "tcp://${projectNetwork.endpoint "backend" member port}";
            }
          ) (lib.attrValues ports)
        ) (lib.toList project.roles.app)
      )
      ++ [
        (endpoint "router" {
          url = "https://${project.hostName}/";

          conditions = [
            "[STATUS] == 200"
            "[CERTIFICATE_EXPIRATION] > 168h"
          ];
        })
      ]
      ++ lib.optionals ((project.authorizationPolicy or null) != null) [
        (endpoint "sso" {
          client.ignore-redirect = true;
          url = "https://${project.hostName}/manage";

          conditions = [
            "[STATUS] == 302"
            "[CERTIFICATE_EXPIRATION] > 168h"
          ];
        })
      ]
    );
  };
}
