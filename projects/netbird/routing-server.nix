projectArgs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  client = config.services.netbird.clients.lab;
  backend = config.networking.firewall.backend;
in
{
  imports = [ (import ./client.nix projectArgs) ];
  services.netbird.useRoutingFeatures = "server";

  networking.firewall.extraForwardRules = lib.mkIf (backend == "nftables") ''
    iifname ${builtins.toJSON client.interface} accept
  '';

  services.firewalld.packages = lib.mkIf (backend == "firewalld") [
    (pkgs.writeTextDir "lib/firewalld/policies/netbird-routing-peer.xml" ''
      <?xml version="1.0" encoding="utf-8"?>
      <policy target="ACCEPT" priority="-1">
        <ingress-zone name="netbird"/>
        <egress-zone name="ANY"/>
      </policy>
    '')
  ];
}
