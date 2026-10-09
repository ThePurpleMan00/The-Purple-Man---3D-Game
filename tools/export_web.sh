#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
godot_state="/workspace/.cloud-environment/godot"
export XDG_CONFIG_HOME="$godot_state/config"
export XDG_DATA_HOME="$godot_state/data"
export XDG_CACHE_HOME="$godot_state/cache"
export XDG_RUNTIME_DIR="$godot_state/runtime"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR" "$project_dir/builds/web"
chmod 700 "$XDG_RUNTIME_DIR"
touch "$project_dir/builds/.gdignore"

log_path="$(mktemp /tmp/purple-man-export.XXXXXX)"
trap 'rm -f "$log_path"' EXIT
if "$godot_bin" --headless --path "$project_dir" --export-release Web \
    "$project_dir/builds/web/index.html" >"$log_path" 2>&1; then
    status=0
else
    status=$?
fi
cat "$log_path"
if (( status != 0 )); then
    exit "$status"
fi
if rg -q 'SCRIPT ERROR:|ERROR:' "$log_path"; then
    printf 'Godot reported an error while exporting the browser build.\n' >&2
    exit 1
fi
for extension in html js wasm pck; do
    test -s "$project_dir/builds/web/index.$extension"
done
python3 - "$project_dir/builds/web/index.html" <<'PY'
from pathlib import Path
import sys
html = Path(sys.argv[1])
html.write_text(html.read_text().rstrip() + '\n')
PY
touch "$project_dir/builds/web/.nojekyll"
"$godot_bin" --headless --path "$project_dir" --script res://tools/write_web_notices.gd
printf 'Browser build exported to %s/builds/web\n' "$project_dir"
