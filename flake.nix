{
  description = "Ozzie's NixOS lab configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = _: {
    lib = import ./lib;

    nixosModules = {
      default = import ./.;
    };
  };
}
