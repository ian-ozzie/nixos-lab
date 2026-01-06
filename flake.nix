{
  description = "Ozzie's NixOS lab configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      systems = [ "x86_64-linux" ];
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (
        system:
        let
          inherit (nixpkgs.legacyPackages.${system}) mkShell;

          pkgs = import nixpkgs {
            inherit system;
          };
        in
        {
          default = mkShell {
            packages = with pkgs; [
              nixd
            ];
          };
        }
      );

      lib = import ./lib;

      nixosModules = {
        default = import ./.;
      };
    };
}
