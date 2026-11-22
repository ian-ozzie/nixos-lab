projectArgs:
{
  config,
  constellation,
  lib,
  ...
}:
let
  domain = lib.removeSuffix "." constellation.domain;
in
{
  imports = [ (import ./local.nix projectArgs { serveRecords = false; }) ];

  ozzie.lab.resolver.upstreams = projectArgs.serverAddresses;

  services.unbound.settings.server = lib.mkIf (config.ozzie.lab.resolver.backend == "unbound") {
    domain-insecure = [ domain ];
    local-zone = [ ''"${domain}." transparent'' ];
  };
}
