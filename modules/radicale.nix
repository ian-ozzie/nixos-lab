{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.radicale;
  service = config.services.radicale;
in
{
  options.ozzie.lab.radicale = {
    enable = lib.mkEnableOption "opinionated radicale config";
  };

  config = lib.mkIf cfg.enable {
    services.radicale = {
      enable = true;

      settings = {
        storage.filesystem_folder = lib.mkDefault "/data/services/radicale/collections";

        auth = {
          htpasswd_encryption = lib.mkDefault "autodetect";
          htpasswd_filename = lib.mkDefault "/data/services/radicale/users";
          type = lib.mkDefault "htpasswd";
        };
      };
    };

    systemd = {
      tmpfiles.rules = lib.unique (
        [
          "d ${dirOf service.settings.storage.filesystem_folder} 0700 ${service.user} ${service.group}"
          "d ${service.settings.storage.filesystem_folder} 0700 ${service.user} ${service.group}"
        ]
        ++ lib.optionals (service.settings.auth.type == "htpasswd") [
          "d ${dirOf service.settings.auth.htpasswd_filename} 0700 ${service.user} ${service.group}"
          "f ${service.settings.auth.htpasswd_filename} 0700 ${service.user} ${service.group}"
        ]
      );
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/networking/radicale.nix"
      "pkgs/by-name/ra/radicale/package.nix"
    ];
  };
}
