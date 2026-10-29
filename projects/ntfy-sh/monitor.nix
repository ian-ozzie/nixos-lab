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
    "[BODY].healthy == true"
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
            url = "http://${projectNetwork.endpoint "backend" member port}/v1/health";
          }
        ) (lib.toList project.roles.app)
      )
      ++ [
        (endpoint "router" {
          conditions = healthConditions ++ [ "[CERTIFICATE_EXPIRATION] > 168h" ];
          url = "https://${project.hostName}/v1/health";
        })
      ]
    );
  };
}
