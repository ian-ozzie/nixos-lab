{
  database,
  localDatabase,
  project,
  projectNetwork,
  ...
}:
{ config, lib, ... }:
let
  appClients = projectNetwork.addresses "backend" project.roles.app;

  clients = lib.unique (
    appClients ++ projectNetwork.addresses "backend" (project.roles.monitor or [ ])
  );
in
{
  ozzie.lab.mysql = {
    enable = true;

    databases.${database} = {
      hosts = if localDatabase then [ "localhost" ] else appClients;
      passwordFile = if localDatabase then null else project.mysql.passwordFile or null;
      user = if localDatabase then config.services.caddy.user else database;
    };
  };

  services.firewalld.zones.nixos-fw-default.rules = lib.mkIf (!localDatabase) (
    map (client: {
      "@family" = projectNetwork.addressFamily client;
      accept = "";
      source."@address" = client;

      port = {
        "@port" = "3306";
        "@protocol" = "tcp";
      };
    }) clients
  );
}
