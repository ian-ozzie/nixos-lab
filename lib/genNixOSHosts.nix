# Based on: https://github.com/arnarg/config/blob/3ea96e9c1df0251add95404c64644d3411733ffb/lib/default.nix

# Discover NixOS configurations.
# It will find all sub-directories in `directory` and
# include it if it has a default.nix.
{
  builder ? nixpkgs.lib.nixosSystem,
  coreModules ? [ ],
  directory ? "${inputs.self}/hosts",
  inputs,
  nixpkgs ? inputs.nixpkgs,
  overlays ? [ ],
  specialArgs ? { },
}:
let
  inherit (builtins)
    attrNames
    concatMap
    filter
    hasAttr
    listToAttrs
    readDir
    ;

  loadHosts =
    dir: inputs:
    let
      loadConf = dir: n: (import "${dir}/${n}" inputs) // { hostname = n; };

      hosts' =
        let
          contents = readDir dir;
        in
        filter (n: contents."${n}" == "directory") (attrNames contents);
    in
    concatMap (
      n:
      let
        contents = readDir "${dir}/${n}";
        hasDefault = (hasAttr "default.nix" contents) && (contents."default.nix" == "regular");
      in
      if hasDefault then [ (loadConf dir n) ] else [ ]
    ) hosts';

  mkHost =
    {
      hostname,
      modules ? [ ],
      system,
    }:
    builder {
      inherit specialArgs system;

      modules = [
        {
          networking.hostName = hostname;

          nixpkgs = {
            inherit overlays;
          };
        }
      ]
      ++ coreModules
      ++ modules;
    };
in
listToAttrs (
  map (conf: {
    name = conf.hostname;
    value = mkHost conf;
  }) (loadHosts directory inputs)
)
