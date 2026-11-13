{
  lib,
  ...
}:
{
  options.meta.ozzie.updateCheck = {
    nixpkgs = lib.mkOption {
      default = [ ];
      description = "paths to monitor within nixpkgs";
      type = lib.types.listOf lib.types.str;
    };
  };
}
