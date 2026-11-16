{ project, ... }:
_: {
  ozzie.lab.beszel-agent.enable = true;

  services.beszel.agent.environment = {
    HUB_URL = "https://${project.hostName}";
    KEY = project.publicKey;
  };
}
