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

    localTTL = lib.mkOption {
      default = 300;
      type = lib.types.int;
      description = "TTL in seconds for generated local records";
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
    services.unbound = {
      enable = true;

      settings = {
        server = {
          prefetch = lib.mkDefault true;

          local-data = lib.flatten (
            lib.mapAttrsToList (
              hostname: addresses:
              map (
                ip:
                let
                  recordType = if lib.hasInfix ":" ip then "AAAA" else "A";
                in
                ''"${fqdn hostname} ${toString cfg.localTTL} IN ${recordType} ${ip}"''
              ) addresses
            ) cfg.hosts
          );
        };
      };
    };
  };
}
