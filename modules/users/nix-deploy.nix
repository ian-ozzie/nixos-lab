{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ozzie.lab.users.nix-deploy;
in
{
  options.ozzie.lab.users.nix-deploy = {
    enable = lib.mkEnableOption "user for automated deployment";
  };

  config = lib.mkIf cfg.enable {
    nix.settings.trusted-users = [ "nix-deploy" ];
    services.openssh.settings.AllowUsers = [ "nix-deploy" ];

    security.sudo.extraRules = [
      {
        users = [ "nix-deploy" ];

        commands = [
          {
            command = "/nix/store/*/activate-rs";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/rm ^/tmp/deploy-rs-canary-[a-z0-9]{32}$";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    users = {
      groups.nix-deploy = { };

      users.nix-deploy = {
        group = "nix-deploy";
        isSystemUser = true;
        shell = with pkgs; bash;
      };
    };
  };
}
