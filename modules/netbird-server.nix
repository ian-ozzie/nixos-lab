{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.netbird-server;
in
{
  options.ozzie.lab.netbird-server = {
    enable = lib.mkEnableOption "opinionated netbird-server config";

    relay.authSecretFile = lib.mkOption {
      type = lib.types.externalPath;
    };

    management = {
      dataStoreEncryptionKeyFile = lib.mkOption {
        type = lib.types.externalPath;
      };

      sessionCookieEncryptionKeyFile = lib.mkOption {
        type = lib.types.externalPath;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.netbird = {
      server = {
        enable = true;
        enableNginx = false;

        management.settings = {
          DataStoreEncryptionKey._secret = cfg.management.dataStoreEncryptionKeyFile;
          DeviceAuthorizationFlow = null;
          PKCEAuthorizationFlow = null;
          Relay.Secret._secret = cfg.relay.authSecretFile;
          StoreConfig.Engine = lib.mkDefault "sqlite";
          TURNConfig.Secret._secret = cfg.relay.authSecretFile;

          EmbeddedIdP = {
            Enabled = true;
            SessionCookieEncryptionKey._secret = cfg.management.sessionCookieEncryptionKeyFile;
          };
        };
      };

      relay = {
        inherit (cfg.relay) authSecretFile;

        enable = true;
        openFirewall = true;

        settings = {
          enable-stun = true;
          health-listen-address = "127.0.0.1:9000";
          listen-address = lib.mkDefault "127.0.0.1:33081";
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/netbird-server 0700 root root"
      ];

      services.netbird-management.serviceConfig.BindPaths = [
        "/data/services/netbird-server:/var/lib/netbird-mgmt/data"
      ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/networking/netbird"
      "pkgs/by-name/ne/netbird-management/package.nix"
      "pkgs/by-name/ne/netbird-signal/package.nix"
      "pkgs/by-name/ne/netbird-relay/package.nix"
      "pkgs/by-name/ne/netbird-dashboard/package.nix"
      "pkgs/by-name/ne/netbird/package.nix"
    ];
  };
}
