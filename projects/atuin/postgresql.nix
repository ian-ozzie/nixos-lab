{
  localDatabase,
  project,
  projectName,
  projectNetwork,
  ...
}:
{ lib, ... }:
let
  clients =
    projectNetwork.addresses "backend" project.roles.app
    ++ projectNetwork.addresses "backend" (project.roles.monitor or [ ]);
in
{
  ozzie.lab.postgresql = {
    enable = true;

    databases.${projectName} = {
      hosts = lib.mkIf (!localDatabase) (projectNetwork.addresses "backend" project.roles.app);
      passwordFile = if localDatabase then null else project.postgresql.passwordFile or null;
      user = if localDatabase then "atuin" else projectName;
    };
  };

  services.firewalld.zones.nixos-fw-default.rules = lib.mkIf (!localDatabase) (
    map (client: {
      "@family" = projectNetwork.addressFamily client;
      accept = "";
      source."@address" = client;

      port = {
        "@port" = "5432";
        "@protocol" = "tcp";
      };
    }) clients
  );
}
