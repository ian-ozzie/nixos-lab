{
  description = "Ozzie's NixOS lab configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = _: {
    lib = import ./lib;

    nixosModules = {
      default = import ./.;
    };
  };
}
