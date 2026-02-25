#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Temporary guardrail during ARB migration:
# - `context.tr(...)` is only allowed in the bridge helper itself.
# - Migrate any hits in user-facing feature/shared code to AppLocalizations.

ALLOWLIST=(
  "$ROOT/lib/core/l10n/context_i18n.dart"
)

HITS=()
while IFS= read -r line; do
  HITS+=("$line")
done < <(rg -n "context\\.tr\\(" "$ROOT/lib" || true)

if [[ ${#HITS[@]} -eq 0 ]]; then
  echo "OK: no context.tr(...) usage found."
  exit 0
fi

FILTERED=()
for line in "${HITS[@]}"; do
  file="${line%%:*}"
  allowed=false
  for a in "${ALLOWLIST[@]}"; do
    if [[ "$file" == "$a" ]]; then
      allowed=true
      break
    fi
  done
  if [[ "$allowed" == false ]]; then
    FILTERED+=("$line")
  fi
done

if [[ ${#FILTERED[@]} -gt 0 ]]; then
  echo "FAIL: context.tr(...) usage found outside allowlist:"
  printf '%s\n' "${FILTERED[@]}"
  exit 1
fi

echo "OK: only allowlisted context.tr(...) usage remains."
