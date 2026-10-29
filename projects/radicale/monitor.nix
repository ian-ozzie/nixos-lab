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
            url = "http://${projectNetwork.endpoint "backend" member port}/.web/";
          }
        ) (lib.toList project.roles.app)
      )
      ++ [
        (endpoint "router" {
          conditions = healthConditions ++ [ "[CERTIFICATE_EXPIRATION] > 168h" ];
          url = "https://${project.hostName}/.web/";
        })
      ]
    );
  };
}
