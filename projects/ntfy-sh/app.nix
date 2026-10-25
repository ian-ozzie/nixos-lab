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
  ozzie.lab.ntfy-sh.enable = true;

  services = {
    ntfy-sh.settings = {
      base-url = "https://${project.hostName}";
      behind-proxy = true;

      listen-http =
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
