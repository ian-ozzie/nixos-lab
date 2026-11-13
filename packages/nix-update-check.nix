{
  git,
  homeManagerPaths ? [ ],
  lib,
  paths ? [ ],
  writeShellApplication,
  writeText,
}:
let
  homeManagerPathsFile = writeText "home-manager-update-check-paths" (
    lib.concatLines (lib.sort builtins.lessThan (lib.unique homeManagerPaths))
  );

  pathsFile = writeText "nix-update-check-paths" (
    lib.concatLines (lib.sort builtins.lessThan (lib.unique paths))
  );
in
writeShellApplication {
  name = "nix-update-check";
  runtimeInputs = [ git ];

  text = ''
    diff=false
    if [[ "''${1:-}" == --diff ]]; then
      diff=true
      shift
    fi

    if (( $# != 4 )); then
      printf 'Usage: %s [--diff] <repository> <checkout> <old-rev> <new-rev>\n' "$0" >&2
      exit 1
    fi

    repository=$1
    checkout=$2
    old_rev=$3
    new_rev=$4

    case "$repository" in
      nixpkgs) paths_file="${pathsFile}" ;;
      home-manager) paths_file="${homeManagerPathsFile}" ;;
      *)
        printf 'No checked paths for %s\n' "$repository" >&2
        exit 0
        ;;
    esac

    if [[ ! -s "$paths_file" ]]; then
      printf 'No checked paths for %s\n' "$repository" >&2
      exit 0
    fi

    mapfile -t paths < "$paths_file"

    git -C "$checkout" fetch origin
    for rev in "$old_rev" "$new_rev"; do
      if ! git -C "$checkout" rev-parse --verify --quiet "$rev^{commit}" > /dev/null; then
        git -C "$checkout" fetch origin "$rev"
      fi
    done

    if "$diff"; then
      git -C "$checkout" diff "$old_rev" "$new_rev" -- "''${paths[@]}"
    else
      git -C "$checkout" log --no-merges --oneline "$old_rev..$new_rev" -- "''${paths[@]}"
    fi
  '';
}
