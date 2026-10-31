{
  project,
  ...
}:
{ lib, ... }:
let
  runners = project.runners or [ ];
in
{
  ozzie.lab.forgejo-runner = {
    inherit runners;

    enable = true;
  };

  services.forgejo-runner.instances = lib.genAttrs runners (_: {
    settings.server.connections.default.url = "https://${project.hostName}";
  });
}
