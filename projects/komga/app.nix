{
  localApp,
  port,
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
  clients =
    projectNetwork.addresses "backend" project.roles.router
    ++ projectNetwork.addresses "backend" (project.roles.monitor or [ ]);
in
{
  ozzie.lab.komga.enable = true;

  services = {
    komga.settings.server = {
      inherit port;

      address = if localApp then "127.0.0.1" else projectNetwork.address "backend" memberName;
    };

    firewalld.zones.nixos-fw-default.rules = lib.mkIf (!localApp) (
      map (client: {
        "@family" = projectNetwork.addressFamily client;
        accept = "";
        source."@address" = client;

        port = {
          "@port" = toString port;
          "@protocol" = "tcp";
        };
      }) clients
    );
  };
}
