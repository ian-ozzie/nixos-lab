{
  port,
  project,
  projectNetwork,
  ...
}:
{
  config,
  memberName,
  ...
}:
{
  services.netbird.server.dashboard = {
    enable = true;
    managementServer = "https://${project.hostName}";

    settings = {
      AUTH_AUDIENCE = "netbird-dashboard";
      AUTH_AUTHORITY = "https://${project.hostName}/oauth2";
      AUTH_CLIENT_ID = "netbird-dashboard";
      AUTH_REDIRECT_URI = "/nb-auth";
      AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
      AUTH_SUPPORTED_SCOPES = "openid profile email groups";
    };
  };

  ozzie.lab.caddy = {
    enable = true;

    sites.${project.hostName} = {
      listenAddresses = [ (projectNetwork.address "frontend" memberName) ];
      upstreams = [ "127.0.0.1:${toString port}" ];

      extraConfig = ''
        @signalGrpc path /signalexchange.SignalExchange/*
        handle @signalGrpc {
          reverse_proxy h2c://127.0.0.1:${toString config.services.netbird.server.signal.port}
        }

        @signalWebSocket path /ws-proxy/signal*
        handle @signalWebSocket {
          reverse_proxy 127.0.0.1:${toString config.services.netbird.server.signal.port}
        }

        @relay path /relay*
        handle @relay {
          reverse_proxy ${config.services.netbird.relay.settings.listen-address}
        }

        @grpc path /management.ManagementService/* /management.ProxyService/*
        handle @grpc {
          reverse_proxy h2c://127.0.0.1:${toString port}
        }

        @backend path /ws-proxy/management* /api/* /oauth2/*
        handle @backend {
          reverse_proxy 127.0.0.1:${toString port}
        }

        handle {
          root * ${config.services.netbird.server.dashboard.finalDrv}
          try_files {path} {path}.html {path}/ =404
          file_server
        }

        handle_errors {
          root * ${config.services.netbird.server.dashboard.finalDrv}
          rewrite * /404.html
          file_server
        }
      '';
    };
  };
}
