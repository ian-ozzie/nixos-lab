{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.unbound;
in
{
  options.ozzie.lab.unbound = {
    enable = lib.mkEnableOption "opinionated unbound config";

    entries = lib.mkOption {
      default = { };
      description = "ip = [ hosts ] to assign as local-data";
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    };

    interface = lib.mkOption {
      default = [ "127.0.0.80" ];
      description = "default host to bind unbound to";
      type = lib.types.listOf lib.types.str;
    };

    port = lib.mkOption {
      default = 5353;
      description = "default port to bind unbound to";
      type = lib.types.int;
    };

    zone-redirects = lib.mkOption {
      default = [ ];
      description = "[ zones ] to redirect";
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    services.unbound = {
      enable = true;
      package = with pkgs; unbound-with-systemd;

      settings = {
        # local-zone = builtins.map (zone: ''"${zone}." redirect'') cfg.zone-redirects;

        local-data = lib.flatten (
          lib.mapAttrsToList (
            ip: hostnames: builtins.map (hostname: ''"${hostname}. A ${ip}"'') hostnames
          ) cfg.entries
        );

        server = {
          inherit (cfg) interface port;

          cache-max-negative-ttl = 60;
          cache-max-ttl = 60;
          do-ip4 = true;
          do-ip6 = false;
          prefetch = true;
          serve-original-ttl = true;
        };
      };
    };
  };
}
