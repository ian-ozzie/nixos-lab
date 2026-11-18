{
  project,
  projectName,
  ...
}:
{
  ozzie.lab.gatus = {
    enable = true;

    endpoints."${projectName}-router" = {
      name = "router";
      group = projectName;
      url = "https://${project.hostName}/auth/login";

      conditions = [
        "[STATUS] == 200"
        "[CERTIFICATE_EXPIRATION] > 168h"
      ];
    };
  };
}
