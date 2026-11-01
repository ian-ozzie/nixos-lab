{
  localApp,
  port,
  project,
  projectNetwork,
  putSources,
  ...
}:
{
  lib,
  memberName,
  ...
}:
{
  ozzie.lab.caddy = {
    enable = true;

    sites.${project.hostName} = {
      extraConfig = ''
        @put {
          method PUT
          ${lib.optionalString (putSources != [ ]) "not remote_ip ${lib.concatStringsSep " " putSources}"}
        }

        respond @put 403
      '';

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
