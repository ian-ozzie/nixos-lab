{
  project,
  ...
}:
_:
let
  substituter = "https://${project.hostName}";
in
{
  # opt-in per session, so a broken cache can be bypassed with `NIX_CONFIG= nixos-rebuild ...`
  environment.variables.NIX_CONFIG = "extra-substituters = ${substituter}";

  nix.settings = {
    trusted-public-keys = [ project.publicKey ];
    trusted-substituters = [ substituter ];
  };
}
