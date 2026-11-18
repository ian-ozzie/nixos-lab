{
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
  cookieDomain =
    project.cookieDomain
      or (lib.concatStringsSep "." (lib.tail (lib.splitString "." project.hostName)));
in
{
  ozzie.lab.caddy = {
    enable = true;

    security = {
      local = true;
      persistState = true;

      portals.local = ''
        crypto default token lifetime 900

        cookie domain ${builtins.toJSON cookieDomain}
        cookie path /
        cookie same site lax
        cookie insecure disabled
      '';
    };

    sites.${project.hostName} = {
      listenAddresses = [ (projectNetwork.address "frontend" memberName) ];

      extraConfig = ''
        route {
          redir / /auth/ 302
          redir /auth /auth/ 301
          authenticate with local at /auth
        }
      '';
    };
  };
}
