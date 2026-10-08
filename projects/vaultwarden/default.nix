projectArgs:
let
  inherit (projectArgs) project projectName;

  localDatabase = (project.roles.app or null) == (project.roles.mysql or null);

  roleArgs = projectArgs // {
    inherit localDatabase;
  };
in
{
  common = { lib, ... }: {
    assertions = [
      {
        assertion = lib.isString (project.roles.app or null);
        message = "Project '${projectName}': role 'app' must name one member";
      }
      {
        assertion = lib.isString (project.roles.mysql or null);
        message = "Project '${projectName}': role 'mysql' must name one member";
      }
      {
        assertion = localDatabase || lib.isString (project.mysql.passwordFile or null);
        message = "Project '${projectName}': 'mysql.passwordFile' is required";
      }
    ];
  };

  app = import ./app.nix roleArgs;
  monitor = import ./monitor.nix roleArgs;
  mysql = import ./mysql.nix roleArgs;
  router = import ./router.nix roleArgs;
}
