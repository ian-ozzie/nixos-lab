# WIP NixOS lab configuration

## Tasks

### test

Validate flake

```
nix flake check
```

### lock

Lock flake inputs

```
nix flake lock
```

### update

Update all/specific flake

Inputs: FLAKE
Environment: FLAKE=

```
nix flake update $FLAKE
```

### check

Check flake outputs

```
nix flake check
```

### inputs

Check flake inputs

```
nix flake metadata
```
