{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.ntfy-sh;
  ntfy = config.services.ntfy-sh;
in
{
  options.ozzie.lab.ntfy-sh = {
    enable = lib.mkEnableOption "opinionated ntfy-sh config";
  };

  config = lib.mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;

      settings = {
        template-dir = lib.mkDefault "/data/services/ntfy-sh/templates";
      };
    };

    users = {
      groups.ntfy-sh = { };

      users.ntfy-sh = {
        group = "ntfy-sh";
        isSystemUser = true;
      };
    };

    systemd = {
      services.ntfy-sh.serviceConfig.BindPaths = [
        "/data/services/ntfy-sh:/var/lib/ntfy-sh"
      ];

      tmpfiles.rules = lib.unique [
        "d /data/services/ntfy-sh 0700 ntfy-sh ntfy-sh"
        "d ${dirOf ntfy.settings.template-dir} 0700 ntfy-sh ntfy-sh"
        "d ${ntfy.settings.template-dir} 0700 ntfy-sh ntfy-sh"
      ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/misc/ntfy-sh.nix"
      "pkgs/by-name/nt/ntfy-sh/package.nix"
    ];
  };
}
