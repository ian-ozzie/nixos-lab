{
  localApp,
  port,
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
      authorizationPolicy = project.authorizationPolicy or null;

      authorizationBypasses = [
        {
          paths = [ "/opds/*" ];
        }
        {
          paths = [ "/api/v1/claim" ];
          sources = projectNetwork.addresses "frontend" (project.roles.monitor or [ ]);
        }
      ];

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
