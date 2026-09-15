#!/usr/bin/env bash
set -euo pipefail

PAT="${PAT:?}"
REPO="PascalHuijsmans/raspberry-pihole"
FILE="blocklist.txt"
DEST="/etc/pihole/private-lists/blocklist.txt"
ETAG="$DEST.etag"
TMP="$(mktemp)"
trap 'rm -f "$TMP" "$TMP.h"' EXIT

code=$(curl -fsSL -w '%{http_code}' -D "$TMP.h" \
  -H "Authorization: Bearer $PAT" \
  -H "Accept: application/vnd.github.raw" \
  ${ETAG:+$([ -f "$ETAG" ] && echo -H "If-None-Match: $(cat "$ETAG")")} \
  "https://api.github.com/repos/$REPO/contents/$FILE" \
  -o "$TMP" || true)

[ "$code" = 304 ] && exit 0
[ "$code" = 200 ] || { echo "http $code" >&2; exit 1; }

if ! cmp -s "$TMP" "$DEST"; then
  install -m 644 "$TMP" "$DEST"
  awk 'tolower($1)=="etag:"{print $2}' "$TMP.h" | tr -d '\r' > "$ETAG"
  pihole -g >/dev/null
fi