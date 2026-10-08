{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.forgejo;
in
{
  options.ozzie.lab.forgejo = {
    enable = lib.mkEnableOption "opinionated forgejo config";

    ssh = lib.mkEnableOption "configure openssh for access" // {
      default = cfg.enable;
    };

    sso = lib.mkEnableOption "configure sso for access" // {
      default = false;
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
      package = with pkgs; forgejo;
      repositoryRoot = "/data/services/forgejo/repos";
      stateDir = "/data/services/forgejo";
      user = lib.mkDefault cfg.user;

      settings = {
        log.LEVEL = "Info";
        session.COOKIE_SECURE = true;

        security = lib.mkIf cfg.sso {
          REVERSE_PROXY_AUTHENTICATION_EMAIL = "X-Token-User-Email";
          REVERSE_PROXY_AUTHENTICATION_FULL_NAME = "X-Token-User-Name";
          REVERSE_PROXY_AUTHENTICATION_USER = "X-Token-User-Login";
          REVERSE_PROXY_TRUSTED_PROXIES = cfg.ssoProxy;
        };

        server = {
          HTTP_PORT = 8386;
          PROTOCOL = "http";
          SSH_PORT = 22;
        };

        service = lib.mkIf cfg.sso {
          ENABLE_REVERSE_PROXY_AUTHENTICATION = true;
          ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = true;
          ENABLE_REVERSE_PROXY_EMAIL = true;
          ENABLE_REVERSE_PROXY_FULL_NAME = true;
        };
      };
    };

    users.users = lib.mkIf (cfg.user == "git") {
      git = {
        inherit (config.services.forgejo) group;

        home = config.services.forgejo.stateDir;
        isSystemUser = true;
        useDefaultShell = true;

        packages = with pkgs; [
          forgejo
        ];
      };
    };
  };
}
