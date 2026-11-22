projectArgs:
let
  inherit (projectArgs) project projectName;

  database = "wordpress_${builtins.substring 0 16 (builtins.hashString "sha256" projectName)}";
  localApp = (project.roles.router or null) == (project.roles.app or null);
  localDatabase = (project.roles.app or null) == (project.roles.mysql or null);

  phpRuntime = { lib, pkgs, ... }: {
    ozzie.lab.php-app = {
      enable = true;
      apps.${projectName}.phpPackage = lib.mkIf (project ? phpPackage) (project.phpPackage pkgs);
    };
  };

  roleArgs = projectArgs // {
    inherit
      database
      localApp
      localDatabase
      phpRuntime
      ;
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
