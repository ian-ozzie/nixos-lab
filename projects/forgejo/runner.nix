{
  project,
  ...
}:
{ lib, ... }:
let
  runners = project.runners or [ ];
in
{
  ozzie.lab.gitea-actions-runner = {
    inherit runners;

    enable = true;
  };

  services.gitea-actions-runner.instances = lib.genAttrs runners (_: {
    url = "https://${project.hostName}";
  });
}
