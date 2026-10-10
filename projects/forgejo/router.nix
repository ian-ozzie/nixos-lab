{
  project,
  projectNetwork,
  ...
}:
{
  memberName,
  ...
}:
{
  ozzie.lab.caddy = {
    enable = true;

    sites.${project.hostName} = {
      upstreams = projectNetwork.endpoints "backend" project.roles.app 8386;

      listenAddresses = [
        (projectNetwork.address "frontend" memberName)
      ];
    };
  };
}
