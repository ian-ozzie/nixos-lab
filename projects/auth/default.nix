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
      {
        message = "Project '${projectName}': 'policies' is required for role 'authorization'";

        assertion =
          lib.toList (project.roles.authorization or [ ]) == [ ] || (project.policies or { }) != { };
      }
    ];
  };

  authorization = import ./authorization.nix projectArgs;
  monitor = import ./monitor.nix projectArgs;
  router = import ./router.nix projectArgs;
}
