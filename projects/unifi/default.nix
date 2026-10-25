projectArgs:
let
  inherit (projectArgs) project projectName;

  toList = value: if builtins.isList value then value else [ value ];

  localApp =
    (project.roles.router or null) != null
    && toList project.roles.router == [ project.roles.app or null ];

  ports = {
    https = 8443;
    inform = 8080;
  };

  roleArgs = projectArgs // {
    inherit localApp ports;
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
