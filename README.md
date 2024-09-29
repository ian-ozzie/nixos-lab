# WIP NixOS lab configuration

## Tasks

### lock

Lock flake inputs

```bash
nix flake lock
```

### update

Update all/specific flake

Inputs: MODULE
Environment: MODULE=

```bash
nix flake update $MODULE
```

### check

Check flake outputs

```bash
nix flake check
```

### inputs

Check flake inputs

```bash
nix flake metadata
```

### test

Validate flake

```bash
nix flake check
```
