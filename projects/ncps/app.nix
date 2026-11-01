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
let
  clients =
    projectNetwork.addresses "backend" project.roles.router
    ++ projectNetwork.addresses "backend" (project.roles.monitor or [ ]);
in
{
  ozzie.lab.ncps.enable = true;

  services = {
    ncps = {
      cache = {
        inherit (project) hostName;

        allowPutVerb = putSources != [ ];
      };

      server.addr =
        if localApp then
          "127.0.0.1:${toString port}"
        else
          projectNetwork.endpoint "backend" memberName port;
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
