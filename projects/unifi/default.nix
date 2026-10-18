projectArgs:
let
  inherit (projectArgs) project projectName;
in
{
  common = { lib, ... }: {
    assertions = [
      {
        assertion = lib.isString (project.roles.app or null);
        message = "Project '${projectName}': role 'app' must name one member";
      }
    ];
  };

  app = import ./app.nix projectArgs;
  monitor = import ./monitor.nix projectArgs;
  router = import ./router.nix projectArgs;
}
