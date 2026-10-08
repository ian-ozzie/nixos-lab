# WIP NixOS lab configuration

## Tasks

### update

Update all/specific input

Inputs: INPUT

Environment: INPUT=

```bash
nix flake update $INPUT
```

### lock

Lock flake inputs

```bash
nix flake lock
```

### check

Check flake

```bash
nix flake check
```

### inputs

Show flake inputs

```bash
nix flake metadata
```

### outputs

Show flake outputs

```bash
nix flake show
```

### test

Used by CI to validate flake

```bash
nix flake check
```
