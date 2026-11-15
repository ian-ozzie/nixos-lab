projectArgs:
let
  inherit (projectArgs) project projectName;

  port = project.port or 33080;

  roleArgs = projectArgs // {
    inherit port;
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
        assertion = lib.toList (project.roles.router or [ ]) == [ (project.roles.app or null) ];
        message = "Project '${projectName}': role 'router' must name the app member so HTTPS and STUN share a public address";
      }
      {
        assertion =
          !(builtins.elem port [
            9000
            9090
            9091
            9092
            8012
            33073
            33081
          ]);
        message = "Project '${projectName}': 'port' must not overlap NetBird's signal, relay, health, metrics or compatibility listeners";
      }
    ];
  };

  app = import ./app.nix roleArgs;
  client = import ./client.nix roleArgs;
  monitor = import ./monitor.nix roleArgs;
  router = import ./router.nix roleArgs;
}
