projectArgs:
let
  inherit (projectArgs) project projectName projectNetwork;

  clients = project.roles.client or [ ];
  forwarders = project.roles.forwarder or [ ];
  servers = project.roles.server or [ ];
  standalone = project.roles.standalone or [ ];

  roleArgs = projectArgs // {
    serverAddresses = projectNetwork.addresses "dns" servers;

    clientMembers = [
      clients
      forwarders
    ];
  };
in
{
  common =
    { lib, ... }:
    let
      members = lib.concatMap lib.toList [
        clients
        forwarders
        servers
        standalone
      ];
    in
    {
      assertions = [
        {
          assertion = lib.length members == lib.length (lib.unique members);
          message = "Project '${projectName}': members must have at most one resolver role";
        }
        {
          assertion = lib.toList servers != [ ] || (lib.toList clients ++ lib.toList forwarders) == [ ];
          message = "Project '${projectName}': 'client' and 'forwarder' require a 'server'";
        }
      ];
    };

  client = import ./client.nix roleArgs;
  forwarder = import ./forwarder.nix roleArgs;
  server = import ./server.nix roleArgs;
  standalone = import ./local.nix roleArgs { serveRecords = true; };
}
