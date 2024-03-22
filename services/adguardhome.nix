{
  pkgs,
  ...
}:
{
  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    firewall.allowedUDPPorts = [ 53 ];
  };

  services = {
    adguardhome = {
      allowDHCP = false;
      enable = true;
      mutableSettings = false;
      openFirewall = false;
      package = with pkgs; adguardhome;

      settings = {
        schema_version = 24;
        theme = "dark";
        users = [ ];

        dns = {
          bind_hosts = [ "0.0.0.0" ];
          fallback_dns = [ "https://9.9.9.9/dns-query" ];
          ports = "53";
          upstream_dns = [ "https://1.1.1.1/dns-query" ];

          bootstrap_dns = [
            "1.1.1.1"
            "9.9.9.9"
          ];
        };

        http = {
          address = "127.0.0.80:8053";
        };
      };
    };
  };
}
