{
  project,
  ...
}:
{ lib, ... }: {
  ozzie.lab.netbird = {
    enable = true;
  };

  services.netbird = {
    useRoutingFeatures = lib.mkDefault (project.useRoutingFeatures or "none");

    clients.lab = {
      environment.NB_MANAGEMENT_URL = "https://${project.hostName}:443";

      config.ManagementURL = {
        Host = "${project.hostName}:443";
        Scheme = "https";
      };
    };
  };
}
