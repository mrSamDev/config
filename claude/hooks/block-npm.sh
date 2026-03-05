#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

if printf '%s' "$input" | grep -Eq '"command"[[:space:]]*:[[:space:]]*"[[:space:]]*npm([[:space:]]|$)'; then
  echo "Blocked: use pnpm, not npm." >&2
  exit 2
fi
