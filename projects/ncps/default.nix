projectArgs:
let
  inherit (projectArgs) project projectName projectNetwork;

  port = project.port or 8501;
  toList = value: if builtins.isList value then value else [ value ];

  localApp =
    (project.roles.router or null) != null
    && toList project.roles.router == [ project.roles.app or null ];

  putSources =
    (project.putSources or [ ]) ++ projectNetwork.addresses "frontend" (project.roles.builder or [ ]);

  roleArgs = projectArgs // {
    inherit localApp port putSources;
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
        assertion = (project.roles.client or [ ]) == [ ] || lib.isString (project.publicKey or null);
        message = "Project '${projectName}': 'publicKey' is required for role 'client'";
      }
    ];
  };

  app = import ./app.nix roleArgs;
  builder = import ./builder.nix roleArgs;
  client = import ./client.nix roleArgs;
  monitor = import ./monitor.nix roleArgs;
  router = import ./router.nix roleArgs;
}
