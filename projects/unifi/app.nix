{
  project,
  projectNetwork,
  ...
}:
{
  lib,
  ...
}:
let
  clients =
    projectNetwork.addresses "backend" project.roles.router
    ++ projectNetwork.addresses "backend" (project.roles.monitor or [ ]);
in
{
  ozzie.lab.unifi.enable = true;

  services.firewalld.zones.nixos-fw-default.rules = lib.concatMap (
    client:
    map
      (port: {
        "@family" = projectNetwork.addressFamily client;
        accept = "";
        source."@address" = client;

        port = {
          "@port" = toString port;
          "@protocol" = "tcp";
        };
      })
      [
        8443
        8080
      ]
  ) clients;
}
