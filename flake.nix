{
  description = "Ozzie's NixOS lab configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    git-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };
  };

  outputs =
    {
      git-hooks,
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

          gitHooks = git-hooks.lib.${system}.run {
            src = ./.;

            hooks = {
              deadnix.enable = true;
              nixfmt.enable = true;

              check-flake = {
                enable = true;
                entry = "nix flake check";
                pass_filenames = false;
                types = [ "nix" ];
              };
            };
          };
        in
        {
          default = mkShell {
            inherit (gitHooks) shellHook;

            buildInputs = gitHooks.enabledPackages;

            packages = with pkgs; [
              nixd
              xc
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
