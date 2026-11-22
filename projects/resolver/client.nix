{
  serverAddresses,
  ...
}:
{
  networking.nameservers = serverAddresses;

  services.resolved = {
    enable = true;

    settings.Resolve = {
      DNSSEC = false;
      FallbackDNS = [ ];
    };
  };
}
