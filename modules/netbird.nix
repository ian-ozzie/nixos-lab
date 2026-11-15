{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.netbird;
  client = config.services.netbird.clients.lab;
in
{
  options.ozzie.lab.netbird = {
    enable = lib.mkEnableOption "opinionated netbird config";

    setupKeyFile = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.externalPath;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      netbird = {
        clients.lab = {
          config.ServerSSHAllowed = lib.mkDefault false;
          dir.state = "/data/services/netbird";
          interface = "wt0";
          port = 51820;

          login = lib.mkIf (cfg.setupKeyFile != null) {
            inherit (cfg) setupKeyFile;

            enable = true;
          };
        };
      };

      firewalld.zones.netbird.ports =
        lib.mkIf (config.networking.firewall.backend == "firewalld" && client.openInternalFirewall)
          [
            {
              port = 22054;
              protocol = "udp";
            }
          ];
    };

    systemd = {
      tmpfiles.rules = [
        "d ${client.dir.state} 0700 ${client.user.name} ${client.user.group}"
      ];

      services = {
        ${client.service.name}.serviceConfig.ReadWritePaths = [ client.dir.state ];

        "${client.service.name}-login" = lib.mkIf client.login.enable {
          serviceConfig.ReadWritePaths = [ client.dir.state ];
        };
      };
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/networking/netbird.nix"
      "pkgs/by-name/ne/netbird/package.nix"
      "pkgs/by-name/ne/netbird-ui/package.nix"
    ];
  };
}
