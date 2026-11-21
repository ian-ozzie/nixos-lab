{
  localApp,
  port,
  project,
  projectNetwork,
  ...
}:
{
  lib,
  memberName,
  ...
}:
let
  authorizationPolicy = project.authorizationPolicy or null;

  bypassPaths = [
    "/api/*"
    "/*/*/info/refs"
    "/*/*/git-upload-pack"
  ];

  identityClaims = {
    X-Token-User-Email = "email";
    X-Token-User-Login = "sub";
    X-Token-User-Name = "name";
  };
in
{
  ozzie.lab.caddy = {
    enable = true;

    security = lib.mkIf (authorizationPolicy != null) {
      policies.${authorizationPolicy} = lib.mkBefore (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (header: claim: "inject header ${header} from ${claim}") identityClaims
        )
      );
    };

    sites.${project.hostName} = {
      inherit authorizationPolicy;

      authorizationBypasses = [
        {
          paths = bypassPaths;
        }
      ];

      extraConfig = lib.optionalString (authorizationPolicy != null) ''
        @forgejoBypass path ${lib.concatMapStringsSep " " builtins.toJSON bypassPaths}
        ${lib.concatMapStringsSep "\n" (header: "request_header @forgejoBypass -${header}") (
          builtins.attrNames identityClaims
        )}
      '';

      listenAddresses = [
        (projectNetwork.address "frontend" memberName)
      ];

      upstreams =
        if localApp then
          [ "127.0.0.1:${toString port}" ]
        else
          projectNetwork.endpoints "backend" project.roles.app port;
    };
  };
}
