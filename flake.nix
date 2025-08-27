{
  description = "Ozzie's NixOS lab configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = _: {
    lib = import ./lib;

    nixosModules = {
      default = import ./.;
    };
  };
}
