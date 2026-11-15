let
  modules = {
    users = import ./users;

    meta = ../shared/meta.nix;

    acme = import ./acme.nix;
    adguardhome = import ./adguardhome.nix;
    atuin = import ./atuin.nix;
    atuin-server = import ./atuin-server.nix;
    caddy = import ./caddy.nix;
    forgejo = import ./forgejo.nix;
    forgejo-runner = import ./forgejo-runner.nix;
    gatus = import ./gatus.nix;
    komga = import ./komga.nix;
    mysql = import ./mysql.nix;
    nat-gateway = import ./nat-gateway.nix;
    ncps = import ./ncps.nix;
    netbird = import ./netbird.nix;
    netbird-server = import ./netbird-server.nix;
    ntfy-sh = import ./ntfy-sh.nix;
    openssh = import ./openssh.nix;
    php-fpm-app = import ./php-fpm-app.nix;
    postgresql = import ./postgresql.nix;
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
