#!/usr/bin/env bash
set -euo pipefail

# pengu-install.sh — install Pengu into the current project (any folder)
# Default source: soyrochus/pengu@main
#
# Usage (most common):
#   curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- -y
#
# The script downloads Dockerfile + pengu into your current directory.

REPO="soyrochus/pengu"
REF="main"
DEST="."
YES=0
WITH_GITIGNORE=0
FILES=("Dockerfile" "pengu")

usage() {
  cat <<EOF
pengu-install.sh — install Pengu into the current folder

Options:
  -y, --yes            Overwrite existing files without asking
  --with-gitignore     Also fetch .gitignore
  --files "A B ..."    Custom list of files to fetch (default: ${FILES[*]})
  --dest PATH          Destination directory (default: $DEST)
  --repo ORG/REPO      Alternative GitHub repo (default: $REPO)
  --ref REF            Branch, tag or commit (default: $REF)

Examples:
  curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- -y
  curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- --with-gitignore -y
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes) YES=1; shift ;;
    --with-gitignore) WITH_GITIGNORE=1; shift ;;
    --files) IFS=' ' read -r -a FILES <<< "${2:-}"; shift 2 ;;
    --dest) DEST="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --ref) REF="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ "$WITH_GITIGNORE" == "1" ]]; then
  FILES+=(".gitignore")
fi

mkdir -p "$DEST"

fetch() {
  local file="$1"
  local url="https://raw.githubusercontent.com/${REPO}/${REF}/${file}"
  local out="${DEST%/}/$(basename "$file")"

  if [[ -e "$out" && "$YES" -ne 1 ]]; then
    read -rp "File '$out' exists. Overwrite? [y/N] " ans
    case "$ans" in
      y|Y|yes|YES) ;;
      *) echo "Skipping $out"; return 0 ;;
    esac
  fi

  echo "Fetching $file from ${REPO}@${REF} …"
  if ! curl -fsSL "$url" -o "$out"; then
    echo "Error: failed to download $url" >&2
    exit 1
  fi
}

for f in "${FILES[@]}"; do
  fetch "$f"
done

# Make helper executable
if [[ -f "${DEST%/}/pengu" ]]; then
  chmod +x "${DEST%/}/pengu"
fi

echo
echo "🐧 Pengu installed in: $DEST"
echo "Next steps:"
echo "  ./pengu up"
echo "  ./pengu shell"
echo