projectArgs:
{
  constellation,
  lib,
  memberName,
  ...
}:
let
  inherit (projectArgs) clientMembers project projectNetwork;

  serverConfig = project.servers.${memberName} or { };
  sources = map (address: { inherit address; }) clientAddresses ++ (serverConfig.sources or [ ]);
  sourcesByZone = lib.groupBy (source: source.zone or "nixos-fw-default") sources;

  clientAddresses = lib.concatMap (
    member:
    lib.optional (
      (constellation.manifests.${member}.network.addresses.${project.networks.dns} or null) != null
    ) (projectNetwork.address "dns" member)
  ) (lib.concatMap lib.toList clientMembers);
in
{
  imports = [ (import ./local.nix projectArgs { serveRecords = true; }) ];

  ozzie.lab.resolver = {
    allowed = lib.mkAfter (lib.unique (map (source: source.address) sources));

    bind = lib.mkAfter (
      [ (projectNetwork.address "dns" memberName) ] ++ (serverConfig.listenAddresses or [ ])
    );
  };

  services.firewalld.zones = lib.mapAttrs (_: zoneSources: {
    rules = lib.concatMap (
      source:
      map
        (protocol: {
          "@family" = projectNetwork.addressFamily source.address;
          accept = "";
          source."@address" = source.address;

          port = {
            "@port" = "53";
            "@protocol" = protocol;
          };
        })
        [
          "tcp"
          "udp"
        ]
    ) (lib.unique zoneSources);
  }) sourcesByZone;
}
