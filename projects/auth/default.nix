projectArgs:
let
  inherit (projectArgs) project projectName;
in
{
  common = { lib, ... }: {
    assertions = [
      {
        assertion = lib.length (lib.toList (project.roles.router or [ ])) == 1;
        message = "Project '${projectName}': role 'router' must name one member";
      }
    ];
  };

  monitor = import ./monitor.nix projectArgs;
  router = import ./router.nix projectArgs;
}
