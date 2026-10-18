{
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
      lib.concatMap (
        member:
        map
          (
            port:
            endpoint "app-${member}-${toString port}" {
              conditions = [ "[CONNECTED] == true" ];
              url = "tcp://${projectNetwork.endpoint "backend" member port}";
            }
          )
          [
            8443
            8080
          ]
      ) (lib.toList project.roles.app)
      ++ [
        (endpoint "router" {
          conditions = [ "[STATUS] == 200" ];
          url = "https://${project.hostName}/";
        })
      ]
    );
  };
}
