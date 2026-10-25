projectArgs:
let
  inherit (projectArgs) project projectName;

  port = project.port or 5232;
  toList = value: if builtins.isList value then value else [ value ];

  localApp =
    (project.roles.router or null) != null
    && toList project.roles.router == [ project.roles.app or null ];

  roleArgs = projectArgs // {
    inherit localApp port;
  };
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

  app = import ./app.nix roleArgs;
  monitor = import ./monitor.nix roleArgs;
  router = import ./router.nix roleArgs;
}
