{
  config,
  lib,
  ...
}:
let
  cfg = config.ozzie.lab.resolver;

  backend = {
    inherit (cfg)
      allowed
      bind
      hosts
      localTTL
      wildcards
      ;

    enable = true;
  };
in
{
  options.ozzie.lab.resolver = {
    enable = lib.mkEnableOption "opinionated dns resolver config";

    allowed = lib.mkOption {
      default = [ "127.0.0.1" ];
      description = "Default addresses to allow";
      type = lib.types.listOf lib.types.str;
    };

    backend = lib.mkOption {
      default = "unbound";
      description = "Resolver to run";
      type = lib.types.enum [
        "adguardhome"
        "unbound"
      ];
    };

    bind = lib.mkOption {
      default = [ "127.0.0.1" ];
      description = "Default host to bind dns resolver to";
      type = lib.types.listOf lib.types.str;
    };

    localTTL = lib.mkOption {
      default = 300;
      type = lib.types.int;
      description = "TTL in seconds for generated local records";
    };

    wildcards = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    };

    hosts = lib.mkOption {
      default = { };
      description = "records to server locally";
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);

      example = {
        "nas.home.arpa" = [
          "192.168.1.10"
          "fd00::10"
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    ozzie.lab = {
      adguardhome = lib.mkIf (cfg.backend == "adguardhome") backend;
      unbound = lib.mkIf (cfg.backend == "unbound") backend;
    };
  };
}
