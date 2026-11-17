{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.vaultwarden;
in
{
  options.ozzie.lab.vaultwarden = {
    enable = lib.mkEnableOption "opinionated vaultwarden config";
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      dbBackend = lib.mkDefault "mysql";
      enable = true;

      config = {
        ROCKET_ADDRESS = lib.mkDefault "127.0.0.1";
        ROCKET_LOG = lib.mkDefault "critical";
        ROCKET_PORT = lib.mkDefault 8222;

        SIGNUPS_ALLOWED = lib.mkDefault false;
      };
    };

    systemd = {
      services.vaultwarden.serviceConfig.BindPaths = [
        "/data/services/vaultwarden:/var/lib/${config.systemd.services.vaultwarden.serviceConfig.StateDirectory}"
      ];

      tmpfiles.rules = [
        "d /data/services/vaultwarden 0700 ${config.users.users.vaultwarden.name} ${config.users.groups.vaultwarden.name}"
      ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/security/vaultwarden/default.nix"
      "pkgs/by-name/va/vaultwarden"
    ];
  };
}
