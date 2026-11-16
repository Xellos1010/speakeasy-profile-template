#!/usr/bin/env bash
# Create your SpeakEasy deployment profile from the example, then validate it. No prompts;
# safe to re-run (an existing profile is kept unless you pass --force).
#
#   scripts/setup.sh [--dest DIR] [--force]
#
# Optional customisation through environment variables (all non-secret):
#   SPEAKEASY_PUBLIC_URL    -> server.public_url and android.server_url  (https://host[:port])
#   SPEAKEASY_PROFILE_NAME  -> profile_name
# Destination: --dest, else $SPEAKEASY_PROFILE if it is a directory path, else
#   ${XDG_CONFIG_HOME:-~/.config}/speakeasy/profile
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PYTHON:-python3}"
DEST=""; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dest) DEST="${2:?--dest needs a directory}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
if [ -z "$DEST" ]; then
  if [ -n "${SPEAKEASY_PROFILE:-}" ] && [ ! -f "${SPEAKEASY_PROFILE}" ]; then DEST="$SPEAKEASY_PROFILE"
  else DEST="${XDG_CONFIG_HOME:-$HOME/.config}/speakeasy/profile"; fi
fi
command -v "$PY" >/dev/null || { echo "python3 not found" >&2; exit 2; }
"$PY" "$HERE/scripts/validate_profile.py" "$HERE/profile.example.json" >/dev/null \
  || { echo "example profile does not validate against the schema" >&2; exit 2; }
mkdir -p "$DEST"; chmod 700 "$DEST"; DEST="$(cd "$DEST" && pwd)"
OUT="$DEST/profile.json"
if [ -f "$OUT" ] && [ "$FORCE" -ne 1 ]; then
  echo "kept existing $OUT (use --force to overwrite)"
else
  ( umask 077
    SPEAKEASY_EXAMPLE="$HERE/profile.example.json" SPEAKEASY_OUT="$OUT" "$PY" - <<'PYEOF'
import json, os
d = json.load(open(os.environ["SPEAKEASY_EXAMPLE"]))
d.pop("$schema", None)
url = os.environ.get("SPEAKEASY_PUBLIC_URL")
if url:
    d["server"]["public_url"] = url.rstrip("/")
    d["android"]["server_url"] = url.rstrip("/")
if os.environ.get("SPEAKEASY_PROFILE_NAME"):
    d["profile_name"] = os.environ["SPEAKEASY_PROFILE_NAME"]
with open(os.environ["SPEAKEASY_OUT"], "w") as f:
    json.dump(d, f, indent=2); f.write("\n")
PYEOF
  )
  echo "wrote $OUT"
fi
"$PY" "$HERE/scripts/validate_profile.py" "$OUT" "$HERE/profile.schema.json" || { echo "profile invalid; edit $OUT" >&2; exit 1; }
echo "Next: point SpeakEasy at it if it is not in the default location:"
echo "  export SPEAKEASY_PROFILE=\"$DEST\""
