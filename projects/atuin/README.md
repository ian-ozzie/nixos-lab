# Atuin

By default registration is disabled, enable with:

```nix
services.atuin.openRegistration = true;
```

## Tasks

### register

Inputs: USER, EMAIL

```bash
atuin register -u $USER -e $EMAIL
```

### login

```bash
atuin login
```

### sync

```bash
atuin sync
```

### import

```bash
atuin import auto
```
