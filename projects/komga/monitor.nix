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
          conditions = healthConditions;
          url = "https://${project.hostName}/api/v1/claim";
        })
      ]
    );
  };
}
