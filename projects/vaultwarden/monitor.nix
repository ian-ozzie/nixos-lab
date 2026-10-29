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
  ];
in
{
  ozzie.lab.gatus = {
    enable = true;

    endpoints = lib.listToAttrs (
      lib.optionals (!localDatabase) (
        map (
          member:
          endpoint "mysql-${member}" {
            conditions = [ "[CONNECTED] == true" ];
            url = "tcp://${projectNetwork.endpoint "backend" member 3306}";
          }
        ) (lib.toList project.roles.mysql)
      )
      ++ lib.optionals (!localApp) (
        map (
          member:
          endpoint "app-${member}" {
            client.ignore-redirect = true;
            conditions = healthConditions;
            headers.Host = project.hostName;
            url = "http://${projectNetwork.endpoint "backend" member port}/alive";
          }
        ) (lib.toList project.roles.app)
      )
      ++ [
        (endpoint "router" {
          client.ignore-redirect = true;
          conditions = healthConditions ++ [ "[CERTIFICATE_EXPIRATION] > 168h" ];
          url = "https://${project.hostName}/alive";
        })
      ]
    );
  };
}
