{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.netbird;
  client = config.services.netbird.clients.lab;
  firewalld = config.networking.firewall.backend == "firewalld";
in
{
  options.ozzie.lab.netbird = {
    enable = lib.mkEnableOption "opinionated netbird config";

    expose = {
      tcp = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.port;
      };

      udp = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.port;
      };

      icmp = lib.mkOption {
        default = false;
        type = lib.types.bool;
      };
    };

    setupKeyFile = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.externalPath;
    };

    waitForStartup = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkIf (!firewalld) {
      interfaces.${client.interface} = {
        allowedTCPPorts = cfg.expose.tcp;
        allowedUDPPorts = cfg.expose.udp;
      };

      extraInputRules = lib.mkIf (cfg.expose.icmp && config.networking.firewall.backend == "nftables") ''
        iifname ${builtins.toJSON client.interface} meta l4proto { icmp, ipv6-icmp } accept
      '';

      extraCommands = lib.mkIf (cfg.expose.icmp && config.networking.firewall.backend == "iptables") ''
        iptables -w -A nixos-fw -i ${lib.escapeShellArg client.interface} -p icmp -j nixos-fw-accept
        ${lib.optionalString config.networking.enableIPv6 ''
          ip6tables -w -A nixos-fw -i ${lib.escapeShellArg client.interface} -p ipv6-icmp -j nixos-fw-accept
        ''}
      '';
    };

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

      firewalld.zones.netbird = lib.mkIf firewalld {
        ports =
          map (port: {
            inherit port;

            protocol = "tcp";
          }) cfg.expose.tcp
          ++ map (port: {
            inherit port;

            protocol = "udp";
          }) cfg.expose.udp
          ++ lib.optionals client.openInternalFirewall [
            {
              port = 22054;
              protocol = "udp";
            }
          ];

        protocols = lib.optionals cfg.expose.icmp [
          "icmp"
          "ipv6-icmp"
        ];
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d ${client.dir.state} 0700 ${client.user.name} ${client.user.group}"
      ];

      services = {
        ${client.service.name}.serviceConfig.ReadWritePaths = [ client.dir.state ];

        "${client.service.name}-ready" = lib.mkIf cfg.waitForStartup {
          requires = [ "${client.service.name}.service" ];
          after = [ "${client.service.name}.service" ];

          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "60s";
          };

          script = ''
            until ${lib.getExe client.wrapper} status --check startup; do
              sleep 1
            done
          '';
        };

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
