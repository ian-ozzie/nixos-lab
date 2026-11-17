{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ozzie.lab.forgejo;
  service = config.services.forgejo;
in
{
  options.ozzie.lab.forgejo = {
    enable = lib.mkEnableOption "opinionated forgejo config";
    sso = lib.mkEnableOption "configure sso for access";

    ssh = lib.mkEnableOption "configure openssh for access" // {
      default = cfg.enable;
    };

    ssoProxy = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Trusted IP that the SSO proxy relays from";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "git";
      description = "User account under which Forgejo runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      repositoryRoot = lib.mkDefault "/data/services/forgejo/repos";
      stateDir = lib.mkDefault "/data/services/forgejo";
      user = lib.mkDefault cfg.user;

      settings = {
        session.COOKIE_SECURE = lib.mkDefault true;

        security = lib.mkIf cfg.sso {
          REVERSE_PROXY_AUTHENTICATION_EMAIL = "X-Token-User-Email";
          REVERSE_PROXY_AUTHENTICATION_FULL_NAME = "X-Token-User-Name";
          REVERSE_PROXY_AUTHENTICATION_USER = "X-Token-User-Login";
          REVERSE_PROXY_TRUSTED_PROXIES = cfg.ssoProxy;
        };

        service = lib.mkIf cfg.sso {
          ENABLE_REVERSE_PROXY_AUTHENTICATION = true;
          ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = true;
          ENABLE_REVERSE_PROXY_EMAIL = true;
          ENABLE_REVERSE_PROXY_FULL_NAME = true;
        };
      };
    };

    services.openssh = lib.mkIf cfg.ssh {
      settings = {
        AcceptEnv = [ "GIT_PROTOCOL" ];
        AllowUsers = [ service.user ];
      };

      extraConfig = ''
        Match User ${cfg.user}
          AuthorizedKeysFile %h/.ssh/authorized_keys
      '';
    };

    users.users = lib.mkIf (cfg.user == "git") {
      git = {
        inherit (service) group;

        home = service.stateDir;
        isSystemUser = true;
        useDefaultShell = true;

        packages = [
          service.package
        ];
      };
    };
  };

  meta = lib.optionalAttrs (options ? meta.ozzie.updateCheck.nixpkgs) {
    ozzie.updateCheck.nixpkgs = [
      "nixos/modules/services/misc/forgejo.nix"
      "pkgs/by-name/fo/forgejo"
    ];
  };
}
