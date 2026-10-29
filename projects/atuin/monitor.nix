{
  localApp,
  localDatabase,
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
    "[BODY].status == healthy"
  ];
in
{
  ozzie.lab.gatus = {
    enable = true;

    endpoints = lib.listToAttrs (
      lib.optionals (!localDatabase) (
        map (
          member:
          endpoint "postgresql-${member}" {
            conditions = [ "[CONNECTED] == true" ];
            url = "tcp://${projectNetwork.endpoint "backend" member 5432}";
          }
        ) (lib.toList project.roles.postgresql)
      )
      ++ lib.optionals (!localApp) (
        map (
          member:
          endpoint "app-${member}" {
            conditions = healthConditions;
            url = "http://${projectNetwork.endpoint "backend" member port}/healthz";
          }
        ) (lib.toList project.roles.app)
      )
      ++ [
        (endpoint "router" {
          conditions = healthConditions ++ [ "[CERTIFICATE_EXPIRATION] > 168h" ];
          url = "https://${project.hostName}/healthz";
        })
      ]
    );
  };
}
