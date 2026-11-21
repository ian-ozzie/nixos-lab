# Caddy

## Examples

### Portal

Configure `caddy-security` with a locally backed auth portal (replacing `example.com` and
`127.0.0.1` with your details).

```nix
{
  ozzie.lab.caddy = {
    environmentFile = "/run/secrets/caddy.env";

    sites = {
      "app.example.com".authorizationPolicy = "users";
    };
  };
}
```

Provision /run/secrets/caddy.env outside the Nix store:

```bash
AUTHP_ADMIN_USER=admin
AUTHP_ADMIN_EMAIL=admin@example.com
AUTHP_ADMIN_SECRET=<private-bootstrap-password>
```

Or if you use `sops-nix`:

```nix
{
  config,
  ...
}:
{
  ozzie.lab.caddy.environmentFile = config.sops.secrets."caddy.env".path;

  sops.secrets."caddy.env" = {
    key = "caddy-env";
    mode = "0400";
    restartUnits = [ "caddy.service" ];
    sopsFile = ./secrets.yaml;
  };
}
```

secrets.yaml

```yaml
caddy-env: |
  AUTHP_ADMIN_USER=admin
  AUTHP_ADMIN_EMAIL=admin@example.com
  AUTHP_ADMIN_SECRET=<private-bootstrap-password>
```

### Portal and apps on separate servers

Run the portal on `server-a` and authorize apps routed by `server-b`

```nix
projects = {
  auth = {
    roles = {
      router = "server-a";

      authorization = [
        "server-b"
      ];
    };

    policies.users = ''
      allow roles staff authp/admin
    '';
  };
};
```

#### server-a

```nix
{
  config,
  ...
}:
{
  ozzie.lab.caddy.security.signingKeyFile = config.sops.secrets.auth-signing-key.path;

  sops.secrets.auth-signing-key = {
    mode = "0400";
    owner = config.services.caddy.user;
    path = "/run/secrets/auth-signing-key.pem";
    restartUnits = [ "caddy.service" ];
    sopsFile = ./secrets.yaml;
  };
}
```

secrets.yaml

```yaml
auth-signing-key: |
  `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out -`
```

#### server-b

```nix
{
  config,
  ...
}:
{
  ozzie.lab.caddy.security.verificationKeyFile = config.sops.secrets.auth-verification-key.path;

  sops.secrets.auth-verification-key = {
    mode = "0400";
    owner = config.services.caddy.user;
    path = "/run/secrets/auth-verification-key.pem";
    restartUnits = [ "caddy.service" ];
    sopsFile = ./secrets.yaml;
  };
}
```

secrets.yaml (public key generated off the signing key on `server-a`)

```yaml
auth-verification-key: |
  `openssl pkey -in auth-signing-key.pem -pubout`
```

### OIDC

This is configuring a Forgejo authentication source named `caddy-security`

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  keyDir = "${config.services.caddy.dataDir}/oidc";
in
{
  ozzie.lab.caddy.security = {
    extraConfig = ''
      oauth application forgejo {
        client_id forgejo
        client_name Forgejo
        client_secret {$FORGEJO_OIDC_SECRET}
        token_endpoint_auth_method client_secret_basic
        redirect_uri https://git.example.com/user/oauth2/caddy-security/callback
        scopes openid profile email
      }
    '';

    portals.local = ''
      oidc provider {
        issuer https://auth.example.com/auth
        realms local
        signing key files ${keyDir}/signing.pem
        applications forgejo
      }
    '';
  };

  sops.secrets = {
    "caddy.env" = {
      key = "caddy-env";
      mode = "0400";
      restartUnits = [ "caddy.service" ];
      sopsFile = ./secrets.yaml;
    };

    caddy-oidc-key = {
      group = config.services.caddy.group;
      mode = "0400";
      owner = config.services.caddy.user;
      restartUnits = [ "caddy.service" ];
      sopsFile = ./secrets.yaml;
    };
  };

  systemd.services.caddy.preStart = ''
    ${pkgs.coreutils}/bin/install -d -m 0700 ${lib.escapeShellArg keyDir}
    ${pkgs.coreutils}/bin/install -m 0600 \
      ${lib.escapeShellArg config.sops.secrets.caddy-oidc-key.path} \
      ${lib.escapeShellArg "${keyDir}/signing.pem"}
  '';
}
```

secrets.yaml (with commands to generate what's needed)

```yaml
caddy-env: |
  FORGEJO_OIDC_SECRET=`openssl rand -hex 32`

caddy-oidc-key: |
  `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out -`
```
