{
  config,
  lib,
  ...
}:
let
  cfg = config.ozzie.lab.redis;
in
{
  options.ozzie.lab.redis = {
    enable = lib.mkEnableOption "opinionated redis config";

    bind = lib.mkOption {
      default = config.ozzie.lab.host.bind.ip;
      description = "address to bind redis to";
      type = lib.types.str;
    };

    maxMemory = lib.mkOption {
      default = "256mb";
      description = "memory limit for redis";
      type = lib.types.str;
    };

    port = lib.mkOption {
      default = 6379;
      description = "port to bind redis to";
      type = lib.types.port;
    };
  };

  config = lib.mkIf cfg.enable {
    services.redis.servers."" = {
      enable = true;

      inherit (cfg) bind port;

      settings = {
        maxmemory = lib.mkDefault cfg.maxMemory;
        maxmemory-policy = lib.mkDefault "noeviction";
      };
    };

    systemd = {
      services = {
        redis = {
          serviceConfig.BindPaths = [ "/data/services/redis:/var/lib/redis" ];
        };
      };

      tmpfiles.rules = [
        "d /data/services/redis 0700 redis redis"
      ];
    };
  };
}
