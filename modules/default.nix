let
  modules = {
    users = import ./users;

    acme = import ./acme.nix;
    adguardhome = import ./adguardhome.nix;
    atuin-daemon = import ./atuin-daemon.nix;
    caddy = import ./caddy.nix;
    forgejo = import ./forgejo.nix;
    gatus = import ./gatus.nix;
    gitea-actions-runner = import ./gitea-actions-runner.nix;
    komga = import ./komga.nix;
    mysql = import ./mysql.nix;
    ncps = import ./ncps.nix;
    netbird = import ./netbird.nix;
    ntfy-sh = import ./ntfy-sh.nix;
    openssh = import ./openssh.nix;
    radicale = import ./radicale.nix;
    redis = import ./redis.nix;
    resolver = import ./resolver.nix;
    syncthing = import ./syncthing.nix;
    unbound = import ./unbound.nix;
    unifi = import ./unifi.nix;
    vaultwarden = import ./vaultwarden.nix;
  };
in
modules
// {
  default = {
    imports = builtins.attrValues modules;
  };
}
