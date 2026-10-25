{
  localApp,
  ports,
  project,
  projectNetwork,
  ...
}:
{
  lib,
  memberName,
  ...
}:
let
  listenAddresses = [ (projectNetwork.address "frontend" memberName) ];

  endpoints =
    port:
    if localApp then
      [ "127.0.0.1:${toString port}" ]
    else
      projectNetwork.endpoints "backend" project.roles.app port;
in
{
  ozzie.lab.caddy = {
    enable = true;

    sites.${project.hostName} = {
      inherit listenAddresses;

      upstreams = map (endpoint: "https://${endpoint}") (endpoints ports.https);

      proxyConfig = ''
        header_up Host {hostport}

        transport http {
          tls_insecure_skip_verify
        }
      '';
    };
  };

  services.caddy.virtualHosts."http://${project.hostName}" = {
    inherit listenAddresses;

    hostName = ":80";

    extraConfig = ''
      handle /inform {
        reverse_proxy ${
          lib.concatStringsSep " " (map (endpoint: "http://${endpoint}") (endpoints ports.inform))
        }
      }

      handle {
        redir https://${project.hostName}{uri} permanent
      }
    '';
  };
}
