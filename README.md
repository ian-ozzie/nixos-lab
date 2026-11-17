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

### show-watched

```
nix eval --json .#updateCheck
```

### update-check

Inputs: REPOSITORY, DIFF

Environment: REPOSITORY=nixpkgs, DIFF=

```bash
diff_args=()
if [[ -n "$DIFF" ]]; then
  diff_args+=("$DIFF")
fi

old_rev=$(jq -er --arg repository "$REPOSITORY" '.nodes[$repository].locked.rev' flake.lock)
ref=$(jq -er --arg repository "$REPOSITORY" '.nodes[$repository].original.ref' flake.lock)

nix run .#nix-update-check -- "${diff_args[@]}" "$REPOSITORY" \
  "/data/nixos/$REPOSITORY" "$old_rev" "origin/$ref"
```
