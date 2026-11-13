let
  modules = {
    meta = ../shared/meta.nix;
  };
in
modules
// {
  default = {
    imports = builtins.attrValues modules;
  };
}
