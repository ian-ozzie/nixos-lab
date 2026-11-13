{
  lib,
  ...
}:
{
  options.meta.ozzie = {
    updateCheck = {
      homeManager = lib.mkOption {
        default = [ ];
        description = "paths to monitor within home-manager";
        type = lib.types.listOf lib.types.str;
      };

      nixpkgs = lib.mkOption {
        default = [ ];
        description = "paths to monitor within nixpkgs";
        type = lib.types.listOf lib.types.str;
      };
    };
  };
}
