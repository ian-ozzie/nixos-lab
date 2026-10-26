{
  localApp,
  port,
  project,
  projectNetwork,
  ...
}:
{ memberName, ... }:
{
  ozzie.lab.caddy = {
    enable = true;

    sites.${project.hostName} = {
      listenAddresses = [
        (projectNetwork.address "frontend" memberName)
      ];

      upstreams =
        if localApp then
          [ "127.0.0.1:${toString port}" ]
        else
          projectNetwork.endpoints "backend" project.roles.app port;
    };
  };
}
