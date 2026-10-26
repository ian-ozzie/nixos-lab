{
  project,
  ...
}:
_:
let
  syncAddress = "https://${project.hostName}";
in
{
  environment.variables.ATUIN_SYNC_ADDRESS = syncAddress;
  ozzie.lab.atuin-daemon.enable = true;
  systemd.user.services.atuin-daemon.environment.ATUIN_SYNC_ADDRESS = syncAddress;
}
