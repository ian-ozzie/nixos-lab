{
  description = "Ozzie's NixOS lab configuration";

  inputs = {
    dev-tools.url = "git+ssh://git/ozzie/nix-dev-tools.git";
    nixpkgs.follows = "dev-tools/nixpkgs";
  };

  outputs =
    {
      dev-tools,
      nixpkgs,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      inherit (dev-tools.lib) forSystem hooks;

      forEachSystem = lib.genAttrs [
        "x86_64-linux"
      ];

      nixHooks = hooks.merge [
        hooks.presets.general
        hooks.presets.nix
      ];
    in
    {
      formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt);
      lib = import ./lib;
      nixosModules = import ./modules;

      checks = forEachSystem (system: {
        lint = (forSystem system).gitHooks.run {
          src = ./.;
          hooks = hooks.without [ "nix-flake-check" ] nixHooks;
        };
      });

      devShells = forEachSystem (system: {
        default = (forSystem system).mkDevShell {
          src = ./.;

          bundles = [
            "common"
            "nix"
          ];

          hooks = nixHooks;
        };
      });
    };
}
