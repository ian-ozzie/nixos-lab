{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.openssh;
in
{
  options.ozzie.lab.openssh = {
    enable = lib.mkEnableOption "opinionated openssh config";
  };

  config = lib.mkIf cfg.enable {
    services = {
      openssh = {
        authorizedKeysInHomedir = lib.mkDefault false;
        enable = true;
        package = with pkgs; openssh;

        hostKeys = [
          {
            bits = 4096;
            path = "/data/services/openssh/ssh_host_rsa_key";
            type = "rsa";
          }
          {
            path = "/data/services/openssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];

        settings = {
          AllowUsers = [ ];
          AuthenticationMethods = "publickey";
          KbdInteractiveAuthentication = false;
          PasswordAuthentication = false;
          PermitRootLogin = lib.mkDefault "no";
        };
      };
    };
  };
}
