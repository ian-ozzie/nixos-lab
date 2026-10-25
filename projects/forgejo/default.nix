projectArgs:
let
  inherit (projectArgs) project projectName;

  localDatabase = (project.roles.app or null) == (project.roles.mysql or null);
  port = project.port or 3000;
  toList = value: if builtins.isList value then value else [ value ];

  localApp =
    (project.roles.router or null) != null
    && toList project.roles.router == [ project.roles.app or null ];

  roleArgs = projectArgs // {
    inherit localApp localDatabase port;
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
      {
        assertion = (project.roles.runner or [ ]) == [ ] || (project.runners or [ ]) != [ ];
        message = "Project '${projectName}': 'runners' is required for role 'runner'";
      }
    ];
  };

  app = import ./app.nix roleArgs;
  monitor = import ./monitor.nix roleArgs;
  mysql = import ./mysql.nix roleArgs;
  router = import ./router.nix roleArgs;
  runner = import ./runner.nix roleArgs;
}
