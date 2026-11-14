{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.nat-gateway;
  format = pkgs.formats.xml { };

  policy = format.generate "firewalld-policy-vpc-router.xml" {
    policy = {
      "@priority" = -1;
      "@target" = "CONTINUE";
      egress-zone."@name" = "nixos-fw-default";
      ingress-zone."@name" = "ANY";

      rule = lib.concatMap (address: [
        {
          "@family" = "ipv4";
          accept = "";
          source."@address" = address;
        }
        {
          "@family" = "ipv4";
          masquerade = "";
          source."@address" = address;
        }
      ]) cfg.internalIPs;
    };
  };
in
{
  options.ozzie.lab.nat-gateway = {
    enable = lib.mkEnableOption "opinionated nat-gateway config";

    externalInterface = lib.mkOption {
      type = lib.types.nonEmptyStr;
    };

    internalIPs = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."firewalld/policies/vpc-router.xml".source = policy;
    networking.nftables.enable = true;
    systemd.services.firewalld.reloadTriggers = [ policy ];

    assertions = [
      {
        assertion = cfg.internalIPs != [ ];
        message = "ozzie.lab.nat-gateway.internalIPs must contain at least one IPv4 address range.";
      }
    ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.send_redirects" = false;
      "net.ipv4.conf.default.send_redirects" = false;
    };

    services.firewalld = {
      enable = true;
      zones.nixos-fw-default.interfaces = [ cfg.externalInterface ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/networking/firewall-firewalld.nix"
      "nixos/modules/services/networking/firewalld"
    ];
  };
}
