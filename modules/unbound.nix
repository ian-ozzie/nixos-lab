{
  config,
  lib,
  ...
}:
let
  cfg = config.ozzie.lab.unbound;
  fqdn = hostname: "${lib.removeSuffix "." hostname}.";
in
{
  options.ozzie.lab.unbound = {
    enable = lib.mkEnableOption "opinionated unbound config";

    allowed = lib.mkOption {
      default = [ "127.0.0.1" ];
      description = "Default addresses to allow";
      type = lib.types.listOf lib.types.str;
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
    networking.nameservers = [ "127.0.0.1" ];

    services.unbound = {
      enable = true;

      settings = {
        server = {
          access-control = map (address: "${address} allow") cfg.allowed;
          interface = cfg.bind;
          local-zone = lib.mapAttrsToList (domain: _: ''"${fqdn domain}" redirect'') cfg.wildcards;
          prefetch = lib.mkDefault true;

          local-data = lib.flatten (
            lib.mapAttrsToList
              (
                hostname: addresses:
                map (
                  ip:
                  let
                    recordType = if lib.hasInfix ":" ip then "AAAA" else "A";
                  in
                  ''"${fqdn hostname} ${toString cfg.localTTL} IN ${recordType} ${ip}"''
                ) addresses
              )
              (
                lib.zipAttrsWith (_: lib.concatLists) [
                  cfg.hosts
                  cfg.wildcards
                ]
              )
          );
        };
      };
    };
  };
}
