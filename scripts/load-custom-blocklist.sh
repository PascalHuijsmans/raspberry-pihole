#!/usr/bin/env bash

export PATH=/usr/local/bin:/usr/bin:/bin

set -euo pipefail

PAT="${PAT:?}"
REPO="PascalHuijsmans/raspberry-pihole"
FILE="blocklist.txt"
DEST="/etc/pihole/private-lists/blocklist.txt"
ETAG="$DEST.etag"
mkdir -p "$(dirname "$DEST")"
TMP="$(mktemp)"
trap 'rm -f "$TMP" "$TMP.h"' EXIT

args=(
  -fsSL -w '%{http_code}' -D "$TMP.h" -o "$TMP"
  -H "Authorization: Bearer $PAT"
  -H "Accept: application/vnd.github.raw"
)
[ -f "$ETAG" ] && args+=(-H "If-None-Match: $(cat "$ETAG")")

code=$(curl "${args[@]}" "https://api.github.com/repos/$REPO/contents/$FILE" || true)

[ "$code" = 304 ] && exit 0
[ "$code" = 200 ] || { echo "http $code" >&2; exit 1; }

if ! cmp -s "$TMP" "$DEST"; then
  install -m 644 "$TMP" "$DEST"
  awk 'tolower($1)=="etag:"{print $2}' "$TMP.h" | tr -d '\r' > "$ETAG"
  pihole -g >/dev/null
fi