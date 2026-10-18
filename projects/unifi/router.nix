{
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
in
{
  ozzie.lab.caddy = {
    enable = true;

    sites.${project.hostName} = {
      inherit listenAddresses;

      proxyConfig = ''
        header_up Host {hostport}

        transport http {
          tls_insecure_skip_verify
        }
      '';

      upstreams = map (endpoint: "https://${endpoint}") (
        projectNetwork.endpoints "backend" project.roles.app 8443
      );
    };
  };

  services.caddy.virtualHosts."http://${project.hostName}" = {
    inherit listenAddresses;

    hostName = ":80";

    extraConfig = ''
      handle /inform {
        reverse_proxy ${
          lib.concatStringsSep " " (
            map (endpoint: "http://${endpoint}") (projectNetwork.endpoints "backend" project.roles.app 8080)
          )
        }
      }

      handle {
        redir https://${project.hostName}{uri} permanent
      }
    '';
  };
}
