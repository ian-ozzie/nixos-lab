{
  config,
  pkgs,
  ...
}:
{
  users.users.traefik.extraGroups = [
    "acme"
    "docker"
  ];

  networking.firewall = {
    allowedUDPPorts = [ 443 ];

    allowedTCPPorts = [
      80
      443
    ];
  };

  services = {
    traefik = {
      enable = true;
      package = with pkgs; traefik;

      staticConfigOptions = {
        accessLog.filePath = "/var/log/traefik-access.log";
        api.dashboard = true;

        certificatesResolvers.cloudflare.acme = {
          storage = "${config.services.traefik.dataDir}/acme.json";

          dnsChallenge = {
            provider = "cloudflare";
            resolvers = [ "1.1.1.1:53" ];
          };
        };

        entryPoints = {
          web = {
            address = ":80";

            http.redirections.entryPoint = {
              scheme = "https";
              to = "websecure";
            };
          };

          websecure = {
            address = ":443";
          };
        };

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        log = {
          filePath = "/var/log/traefik.log";
          level = "INFO";
        };

        providers.docker = {
          exposedByDefault = false;
          watch = true;
        };
      };
    };
  };
}
