#!/usr/bin/env bash
set -euo pipefail

# pengu-install.sh — drop-in installer for Pengu
# Downloads Dockerfile + pengu helper (and optionally .gitignore) from a GitHub repo.
# Works anywhere; ideal for adding Pengu to an existing project folder.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<your-org>/pengu/main/pengu-install.sh | bash -s -- [options]
#
# Options:
#   -y, --yes              Overwrite existing files without prompting
#   --org ORG              GitHub org/user that hosts the Pengu repo      (default: <your-org>)
#   --ref REF              Git ref to download from (branch/tag/commit)   (default: main)
#   --with-gitignore       Also fetch .gitignore
#   --files "A B ..."      Custom space-separated list of files to fetch  (default: Dockerfile pengu)
#   --dest PATH            Destination directory (default: .)
#   -h, --help             Show help
#
# After install:
#   chmod +x pengu
#   ./pengu up
#   ./pengu shell

ORG="<your-org>"
REF="main"
DEST="."
YES=0
WITH_GITIGNORE=0
FILES=("Dockerfile" "pengu")

usage() {
  sed -n '1,100p' "$0" | sed -n '1,80p' | sed -n '1,40p' >/dev/null 2>&1 || true
  cat <<EOF
pengu-install.sh — install Pengu into the current project

Usage:
  $(basename "$0") [options]

Options:
  -y, --yes              Overwrite existing files without prompting
  --org ORG              GitHub org/user that hosts the Pengu repo      (default: $ORG)
  --ref REF              Git ref to download from (branch/tag/commit)   (default: $REF)
  --with-gitignore       Also fetch .gitignore
  --files "A B ..."      Custom space-separated list of files to fetch  (default: ${FILES[*]})
  --dest PATH            Destination directory (default: $DEST)
  -h, --help             Show this help

Examples:
  $(basename "$0") --org my-org --ref main -y
  $(basename "$0") --with-gitignore
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes) YES=1; shift ;;
    --org) ORG="${2:-}"; shift 2 ;;
    --ref) REF="${2:-}"; shift 2 ;;
    --with-gitignore) WITH_GITIGNORE=1; shift ;;
    --files) IFS=' ' read -r -a FILES <<< "${2:-}"; shift 2 ;;
    --dest) DEST="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ "$WITH_GITIGNORE" == "1" ]]; then
  FILES+=(".gitignore")
fi

# Ensure DEST exists
mkdir -p "$DEST"

# Download function
fetch() {
  local file="$1"
  local url="https://raw.githubusercontent.com/${ORG}/pengu/${REF}/${file}"
  local out="${DEST%/}/$(basename "$file")"

  if [[ -e "$out" && "$YES" -ne 1 ]]; then
    read -rp "File '$out' exists. Overwrite? [y/N] " ans
    case "$ans" in
      y|Y|yes|YES) ;;
      *) echo "Skipping $out"; return 0 ;;
    esac
  fi

  echo "Fetching $file …"
  if ! curl -fsSL "$url" -o "$out"; then
    echo "Error: failed to download $url" >&2
    exit 1
  fi
}

# Fetch files
for f in "${FILES[@]}"; do
  fetch "$f"
done

# Make pengu executable if present
if [[ -f "${DEST%/}/pengu" ]]; then
  chmod +x "${DEST%/}/pengu"
fi

echo "🐧 Pengu installed."
echo "Next steps:"
echo "  ./pengu up"
echo "  ./pengu shell"
