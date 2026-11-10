{
  project,
  ...
}:
_: {
  ozzie.lab.atuin.enable = true;
  programs.atuin.settings.sync_address = "https://${project.hostName}";
}
