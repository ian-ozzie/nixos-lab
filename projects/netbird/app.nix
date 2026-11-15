{
  port,
  project,
  ...
}:
_: {
  ozzie.lab.netbird-server.enable = true;

  services.netbird = {
    server = {
      domain = project.hostName;

      management = {
        inherit port;

        oidcConfigEndpoint = "https://${project.hostName}/oauth2/.well-known/openid-configuration";
        turnDomain = project.hostName;

        settings = {
          EmbeddedIdP = {
            CLIRedirectURIs = [ "http://localhost:53000/" ];
            DashboardPostLogoutRedirectURIs = [ "https://${project.hostName}/" ];
            Issuer = "https://${project.hostName}/oauth2";
            SignKeyRefreshEnabled = true;

            DashboardRedirectURIs = [
              "https://${project.hostName}/nb-auth"
              "https://${project.hostName}/nb-silent-auth"
            ];
          };

          TURNConfig = {
            Turns = [ ];
          };

          Relay = {
            Addresses = [ "rels://${project.hostName}:443" ];
            CredentialsTTL = "12h";
          };

          ReverseProxy = {
            TrustedHTTPProxies = [ "127.0.0.1/32" ];
            TrustedPeers = [ ];
          };
        };
      };
    };

    relay = {
      settings.exposed-address = "rels://${project.hostName}:443";
    };
  };
}
