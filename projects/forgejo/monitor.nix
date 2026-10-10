{
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

  healthConditions = [
    "[STATUS] == 200"
    "[BODY].status == pass"
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
      ++ map (
        member:
        endpoint "app-${member}" {
          client.ignore-redirect = true;
          conditions = healthConditions;
          headers.Host = project.hostName;
          url = "http://${projectNetwork.endpoint "backend" member 8386}/api/healthz";
        }
      ) (lib.toList project.roles.app)
      ++ [
        (endpoint "router" {
          client.ignore-redirect = true;
          conditions = healthConditions;
          url = "https://${project.hostName}/api/healthz";
        })
      ]
    );
  };
}
