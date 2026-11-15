{
  project,
  projectName,
  ...
}:
{ lib, ... }:
let
  endpoint = name: settings: {
    name = "${projectName}-${name}";

    value = {
      inherit name;

      group = projectName;
    }
    // settings;
  };
in
{
  ozzie.lab.gatus = {
    enable = true;

    endpoints = lib.listToAttrs [
      (endpoint "router" {
        url = "https://${project.hostName}/oauth2/.well-known/openid-configuration";

        conditions = [
          "[STATUS] == 200"
          "[BODY].issuer == https://${project.hostName}/oauth2"
          "[CERTIFICATE_EXPIRATION] > 168h"
        ];
      })

      (endpoint "dashboard" {
        url = "https://${project.hostName}/";

        conditions = [
          "[STATUS] == 200"
          "[BODY] == pat(*<html*)"
          "[CERTIFICATE_EXPIRATION] > 168h"
        ];
      })

      (endpoint "signal" {
        client.ignore-redirect = true;
        url = "https://${project.hostName}/ws-proxy/signal";

        conditions = [
          "[STATUS] == 426"
          "[CERTIFICATE_EXPIRATION] > 168h"
        ];
      })

      (endpoint "relay" {
        client.ignore-redirect = true;
        url = "https://${project.hostName}/health/relay";

        conditions = [
          "[STATUS] == 200"
          "[BODY].status == healthy"
          "[CERTIFICATE_EXPIRATION] > 168h"
        ];
      })
    ];
  };
}
