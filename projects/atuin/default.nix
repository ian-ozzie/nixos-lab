projectArgs:
let
  inherit (projectArgs) project projectName;

  localDatabase = (project.roles.app or null) == (project.roles.postgresql or null);
  port = project.port or 8888;
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
        assertion = lib.isString (project.roles.postgresql or null);
        message = "Project '${projectName}': role 'postgresql' must name one member";
      }
      {
        assertion = localDatabase || lib.isString (project.postgresql.passwordFile or null);
        message = "Project '${projectName}': 'postgresql.passwordFile' is required";
      }
    ];
  };

  app = import ./app.nix roleArgs;
  client = import ./client.nix roleArgs;
  monitor = import ./monitor.nix roleArgs;
  postgresql = import ./postgresql.nix roleArgs;
  router = import ./router.nix roleArgs;
}
