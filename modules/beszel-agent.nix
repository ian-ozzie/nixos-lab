{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.beszel-agent;
  agent = config.services.beszel.agent;
in
{
  options.ozzie.lab.beszel-agent = {
    enable = lib.mkEnableOption "opinionated beszel agent config";

    tokenFile = lib.mkOption {
      type = lib.types.externalPath;
    };
  };

  config = lib.mkIf cfg.enable {
    services.beszel.agent = {
      dataDir = lib.mkDefault "/data/services/beszel-agent";
      enable = true;
      openFirewall = lib.mkDefault false;

      environment = {
        DISABLE_SSH = lib.mkDefault "true";
        TOKEN_FILE = "/run/credentials/beszel-agent.service/token";
      };
    };

    users = {
      groups.beszel-agent = { };

      users.beszel-agent = {
        group = "beszel-agent";
        isSystemUser = true;
      };
    };

    systemd = {
      services.beszel-agent.serviceConfig = {
        LoadCredential = [ "token:${cfg.tokenFile}" ];
        PrivateDevices = lib.mkIf config.boot.zfs.enabled (lib.mkForce false);
        ReadWritePaths = [ agent.dataDir ];
      };

      tmpfiles.rules = [
        "d ${agent.dataDir} 0700 beszel-agent beszel-agent"
      ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/monitoring/beszel-agent.nix"
      "pkgs/by-name/be/beszel/package.nix"
    ];
  };
}
