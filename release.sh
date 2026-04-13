#!/usr/bin/env bash
set -euo pipefail

# Read version from the manifest (## Version: X.Y.Z)
VERSION=$(grep -m1 '^## Version:' OutfitStylesFavorites.txt | awk '{print $3}' | tr -d '\r')

if [[ -z "$VERSION" ]]; then
  echo "ERROR: could not find '## Version:' in OutfitStylesFavorites.txt" >&2
  exit 1
fi

OUTDIR="releases"
ARCHIVE="${OUTDIR}/OutfitStylesFavorites-${VERSION}.zip"

mkdir -p "$OUTDIR"
git archive --format=zip --prefix=OutfitStylesFavorites/ HEAD -o "$ARCHIVE"
echo "Created: $ARCHIVE"
