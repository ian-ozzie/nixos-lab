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
        enable = true;
        openFirewall = lib.mkDefault true;
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
          KbdInteractiveAuthentication = false;
          PasswordAuthentication = false;
          PermitRootLogin = lib.mkDefault "no";
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /data/services/openssh 0755 root root"
      ];
    };
  };
}
