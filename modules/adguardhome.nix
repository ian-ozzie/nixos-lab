{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.adguardhome;
  service = config.services.adguardhome;

  resolverAddresses = lib.unique (
    map (
      address:
      if address == "0.0.0.0" then
        "127.0.0.1"
      else if address == "::" then
        "::1"
      else
        address
    ) cfg.bind
  );
in
{
  options.ozzie.lab.adguardhome = {
    enable = lib.mkEnableOption "opinionated adguardhome config";

    allowed = lib.mkOption {
      default = [ "127.0.0.1" ];
      description = "Default addresses, CIDR ranges, or client IDs to allow";
      type = lib.types.listOf lib.types.str;
    };

    bind = lib.mkOption {
      default = [ "127.0.0.1" ];
      description = "Addresses to bind the DNS resolver to";
      type = lib.types.listOf lib.types.str;
    };

    domain = lib.mkOption {
      description = "Domain to expose adguardhome under";
      type = lib.types.str;
    };

    expose = lib.mkOption {
      default = null;
      description = "IP to expose adguardhome on via caddy, null to disable";
      type = lib.types.nullOr lib.types.str;
    };

    host = lib.mkOption {
      default = "dns";
      description = "Host prefix to expose adguardhome with domain";
      type = lib.types.str;
    };

    hosts = lib.mkOption {
      default = { };
      description = "Records to serve locally";
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);

      example = {
        "nas.home.arpa" = [
          "192.168.1.10"
          "fd00::10"
        ];
      };
    };

    localTTL = lib.mkOption {
      default = 300;
      type = lib.types.ints.u32;
      description = "TTL in seconds for generated local records, also applied to blocked responses";
    };

    wildcards = lib.mkOption {
      default = { };
      description = "Records to serve locally for each domain and its subdomains";
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.bind != [ ];
        message = "ozzie.lab.adguardhome.bind must contain at least one address";
      }
    ];

    networking.nameservers = resolverAddresses;

    ozzie.lab.caddy = lib.mkIf (cfg.expose != null) {
      enable = true;

      sites."${cfg.host}.${cfg.domain}" = {
        listenAddresses = [ cfg.expose ];
        upstreams = [ service.settings.http.address ];
      };
    };

    services = {
      adguardhome = {
        allowDHCP = false;
        enable = true;
        mutableSettings = false;
        openFirewall = false;

        settings = {
          http.address = lib.mkDefault "127.0.0.1:8053";

          clients = {
            persistent = [
              {
                ids = [ "127.0.0.1" ];
                name = "Local";
                uid = "0197ee4d-041a-7ce9-af4f-a11bfdce5193";
                use_global_blocked_services = true;
                use_global_settings = true;
              }
            ];
          };

          dns = {
            aaaa_disabled = lib.mkDefault false;
            bind_hosts = cfg.bind;
            cache_optimistic = true;
            cache_size = 16777216;
            cache_ttl_max = 14400;
            cache_ttl_min = 900;
            enable_dnssec = true;
            fallback_dns = [ "https://9.9.9.9/dns-query" ];
            port = 53;
            ratelimit_whitelist = resolverAddresses;
            upstream_dns = [ "https://1.1.1.1/dns-query" ];

            allowed_clients = lib.optionals (cfg.allowed != [ ]) (
              lib.unique (cfg.allowed ++ resolverAddresses)
            );

            bootstrap_dns = [
              "1.1.1.1"
              "9.9.9.9"
            ];
          };

          filtering = {
            blocked_response_ttl = cfg.localTTL;
            blocking_mode = "nxdomain";
            filtering_enabled = true;
            filters_update_interval = 168;

            rewrites = lib.flatten [
              (lib.mapAttrsToList (
                domain: addresses:
                map (answer: {
                  inherit answer;

                  domain = lib.removeSuffix "." domain;
                  enabled = true;
                }) addresses
              ) cfg.hosts)
              (lib.mapAttrsToList (
                domain: addresses:
                map (answer: {
                  inherit answer;

                  domain = lib.removeSuffix "." domain;
                  enabled = true;
                }) addresses
                ++ map (answer: {
                  inherit answer;

                  domain = "*.${lib.removeSuffix "." domain}";
                  enabled = true;
                }) addresses
              ) cfg.wildcards)
            ];
          };

          querylog = {
            interval = "168h";
          };

          statistics = {
            interval = "168h";
          };
        };
      };
    };

    users = {
      groups.adguardhome = { };

      users.adguardhome = {
        group = "adguardhome";
        isSystemUser = true;
      };
    };

    systemd = {
      services.adguardhome.serviceConfig.BindPaths = [
        "/data/services/adguardhome:/var/lib/AdGuardHome"
      ];

      tmpfiles.rules = [
        "d /data/services/adguardhome 0700 adguardhome adguardhome"
      ];
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/networking/adguardhome.nix"
      "pkgs/by-name/ad/adguardhome/package.nix"
    ];
  };
}
