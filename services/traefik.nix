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

  services = {
    traefik = {
      enable = true;
      package = with pkgs; traefik;

      staticConfigOptions = {
        api.dashboard = true;
        log.level = "info";
        providers.docker.exposedByDefault = false;

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
      };
    };
  };
}
