{
  project,
  projectName,
  ...
}:
_: {
  ozzie.lab.gatus = {
    enable = true;

    endpoints.${projectName} = {
      group = projectName;
      name = "router";
      url = "https://${project.hostName}/oauth2/.well-known/openid-configuration";

      conditions = [
        "[STATUS] == 200"
        "[BODY].issuer == https://${project.hostName}/oauth2"
        "[CERTIFICATE_EXPIRATION] > 168h"
      ];
    };
  };
}
