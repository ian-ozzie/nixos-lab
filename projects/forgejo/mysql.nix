{
  localDatabase,
  project,
  projectName,
  projectNetwork,
  ...
}:
{
  config,
  lib,
  ...
}:
let
  clients =
    lib.optionals (!localDatabase) (projectNetwork.addresses "backend" project.roles.app)
    ++ projectNetwork.addresses "backend" (project.roles.monitor or [ ]);
in
{
  ozzie.lab.mysql = {
    enable = true;

    databases.${projectName} = {
      passwordFile = if localDatabase then null else project.mysql.passwordFile or null;
      user = if localDatabase then config.services.forgejo.user else projectName;

      hosts =
        if localDatabase then [ "localhost" ] else projectNetwork.addresses "backend" project.roles.app;
    };
  };

  services = lib.mkIf (!localDatabase) {
    firewalld.zones.nixos-fw-default.rules = map (client: {
      "@family" = projectNetwork.addressFamily client;
      accept = "";
      source."@address" = client;

      port = {
        "@port" = "3306";
        "@protocol" = "tcp";
      };
    }) clients;
  };
}
