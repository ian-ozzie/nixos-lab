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
  urlAddress = address: if lib.hasInfix ":" address then "[${address}]" else address;

  upstreams = map (address: "${urlAddress address}:8222") (
    projectNetwork.addresses "backend" project.roles.app
  );
in
{
  ozzie.lab.caddy = {
    enable = true;

    sites.${project.hostName} = {
      inherit upstreams;

      listenAddresses = [
        (projectNetwork.address "frontend" memberName)
      ];
    };
  };
}
