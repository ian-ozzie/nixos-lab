{ project, ... }:
{ serveRecords }:
{
  config,
  constellation,
  lib,
  ...
}:
let
  loopback = [ "127.0.0.1" ] ++ lib.optional config.networking.enableIPv6 "::1";

  peers = lib.filterAttrs (
    _: peer: (peer.network.addresses.${project.networks.dns} or null) != null
  ) constellation.manifests;
in
{
  ozzie.lab.resolver = {
    allowed = loopback;
    bind = loopback;
    enable = true;

    hosts = lib.mkIf serveRecords (
      lib.mapAttrs' (
        _: peer:
        lib.nameValuePair "${peer.identity.hostName}.${constellation.domain}" [
          peer.network.addresses.${project.networks.dns}
        ]
      ) peers
    );
  };

  services.unbound = lib.mkIf (serveRecords && config.ozzie.lab.resolver.backend == "unbound") {
    settings.server.local-zone = [ ''"${constellation.domain}." static'' ];
  };
}
