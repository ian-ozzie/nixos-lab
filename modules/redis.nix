{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.redis;
  server = config.services.redis.servers."";
in
{
  options.ozzie.lab.redis = {
    enable = lib.mkEnableOption "opinionated redis config";
  };

  config = lib.mkIf cfg.enable {
    services.redis.servers."" = {
      enable = true;

      settings = {
        maxmemory = lib.mkDefault "256mb";
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
        "d /data/services/redis 0700 ${server.user} ${server.group}"
      ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/databases/redis.nix"
      "pkgs/by-name/re/redis/package.nix"
    ];
  };
}
