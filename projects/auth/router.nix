{
  project,
  projectName,
  projectNetwork,
  ...
}:
{
  config,
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
  assertions = [
    {
      message = "Project '${projectName}': caddy.security.signingKeyFile is required for role 'authorization'";

      assertion =
        lib.toList (project.roles.authorization or [ ]) == [ ]
        || config.ozzie.lab.caddy.security.signingKeyFile != null;
    }
  ];

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

        ${lib.concatMapStringsSep "\n" (domain: ''
          trust login redirect uri domain exact ${builtins.toJSON domain} path prefix /
          trust login redirect uri domain suffix ${builtins.toJSON ".${domain}"} path prefix /
        '') (project.trustedLoginRedirectDomains or [ cookieDomain ])}
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
