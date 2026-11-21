{
  localApp,
  port,
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

  healthConditions = [
    "[STATUS] == 200"
    "[BODY].isClaimed == true"
  ];
in
{
  ozzie.lab.gatus = {
    enable = true;

    endpoints = lib.listToAttrs (
      lib.optionals (!localApp) (
        map (
          member:
          endpoint "app-${member}" {
            conditions = healthConditions;
            url = "http://${projectNetwork.endpoint "backend" member port}/api/v1/claim";
          }
        ) (lib.toList project.roles.app)
      )
      ++ [
        (endpoint "router" {
          client.ignore-redirect = (project.authorizationPolicy or null) != null;
          conditions = healthConditions ++ [ "[CERTIFICATE_EXPIRATION] > 168h" ];
          url = "https://${project.hostName}/api/v1/claim";
        })
      ]
      ++ lib.optionals ((project.authorizationPolicy or null) != null) [
        (endpoint "sso" {
          client.ignore-redirect = true;
          url = "https://${project.hostName}/";

          conditions = [
            "[STATUS] == 302"
            "[CERTIFICATE_EXPIRATION] > 168h"
          ];
        })
      ]
    );
  };
}
