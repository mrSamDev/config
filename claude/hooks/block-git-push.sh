#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

if printf '%s' "$input" | grep -Eq '"command"[[:space:]]*:[[:space:]]*"[[:space:]]*git[[:space:]]+push([[:space:]]|$)'; then
  echo "Blocked: git push is not allowed." >&2
  exit 2
fi
