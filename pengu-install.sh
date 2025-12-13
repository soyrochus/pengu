#!/usr/bin/env bash
# Pengu - Persistent Linux environment in a container
# Copyright (c) 2025, Iwan van der Kleijn | MIT License
# https://github.com/soyrochus/pengu
set -euo pipefail

# Defaults
REPO="soyrochus/pengu"
REF="refs/heads/main"   # use the path you confirmed works
DEST="."
YES=0

usage() {
  cat <<EOF
pengu-install.sh — install Pengu (macOS/Linux)

Downloads the Pengu helper and default Pengufile into the target folder.

Options:
  -y, --yes            Overwrite existing files without prompting
  --dest PATH          Destination directory (default: .)
  --repo ORG/REPO      GitHub repo to fetch from (default: $REPO)
  --ref REF            Git ref path (default: $REF) — e.g. refs/heads/main

Examples:
  curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/refs/heads/main/pengu-install.sh | bash -s -- -y
  bash pengu-install.sh --dest ./tools/pengu -y
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes) YES=1; shift ;;
    --dest) DEST="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --ref) REF="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

mkdir -p "$DEST"
BASE="https://raw.githubusercontent.com/${REPO}/${REF}"

fetch() {
  local src="$1" dst="$2"
  if [[ -e "$dst" && "$YES" -ne 1 ]]; then
    read -rp "File '$dst' exists. Overwrite? [y/N] " a
    [[ "$a" =~ ^([yY]|yes)$ ]] || { echo "Skipping $dst"; return; }
  fi
  echo "Fetching $src …"
  curl -fsSL "$BASE/$src" -o "$dst"
}

mkdir -p "${DEST%/}/.pengu"

# Download Pengufile (default profile) and Bash helper
fetch "Dockerfile" "${DEST%/}/.pengu/Pengufile"
fetch "pengu"      "${DEST%/}/pengu"

# Make helper executable
chmod +x "${DEST%/}/pengu" || true

echo
echo "🐧 Pengu installed in: $DEST"
echo "Next steps:"
echo "  ./pengu up"
echo "  ./pengu shell"
echo
