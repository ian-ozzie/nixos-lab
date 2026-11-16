projectArgs: _: {
  imports = [ (import ./client.nix projectArgs) ];
  services.netbird.useRoutingFeatures = "client";
}
