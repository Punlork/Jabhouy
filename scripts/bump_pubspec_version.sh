#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") [--dry-run] [pubspec_path]" >&2
}

dry_run=false
pubspec_path="pubspec.yaml"

while (($# > 0)); do
  case "$1" in
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      pubspec_path="$1"
      shift
      ;;
  esac
done

if [[ ! -f "$pubspec_path" ]]; then
  echo "pubspec file not found: $pubspec_path" >&2
  exit 1
fi

version_line="$(grep -E '^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+[[:space:]]*$' "$pubspec_path" | head -n 1 || true)"
if [[ -z "$version_line" ]]; then
  echo "Could not find a pubspec version line like 'version: x.y.z+n' in $pubspec_path" >&2
  exit 1
fi

current_version="${version_line#version: }"
current_version="${current_version//[[:space:]]/}"

if [[ ! "$current_version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$ ]]; then
  echo "Unsupported version format: $current_version" >&2
  exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"
build="${BASH_REMATCH[4]}"

next_patch=$((patch + 1))
next_build=$((build + 1))
next_version="$major.$minor.$next_patch+$next_build"

if [[ "$dry_run" == true ]]; then
  echo "$current_version -> $next_version"
  exit 0
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

awk -v replacement="version: $next_version" '
  BEGIN { updated = 0 }
  /^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+[[:space:]]*$/ && updated == 0 {
    print replacement
    updated = 1
    next
  }
  { print }
  END {
    if (updated == 0) {
      exit 1
    }
  }
' "$pubspec_path" > "$tmp_file"

mv "$tmp_file" "$pubspec_path"
trap - EXIT

echo "Updated $pubspec_path: $current_version -> $next_version"
