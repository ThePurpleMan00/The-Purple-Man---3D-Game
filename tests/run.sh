#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
godot_state="/workspace/.cloud-environment/godot"
export XDG_CONFIG_HOME="$godot_state/config"
export XDG_DATA_HOME="$godot_state/data"
export XDG_CACHE_HOME="$godot_state/cache"
export XDG_RUNTIME_DIR="$godot_state/runtime"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

if ! command -v "$godot_bin" >/dev/null 2>&1; then
    printf 'Godot was not found. Install Godot 4 or set GODOT_BIN.\n' >&2
    exit 1
fi

log_path="$(mktemp /tmp/purple-man-tests.XXXXXX)"
trap 'rm -f "$log_path"' EXIT
if timeout 60s "$godot_bin" --headless --editor --path "$project_dir" \
    --import --quit >"$log_path" 2>&1; then
    :
else
    run_status=$?
    cat "$log_path"
    printf 'Godot project import exited with status %s.\n' "$run_status" >&2
    exit "$run_status"
fi
if timeout 45s "$godot_bin" --headless --path "$project_dir" --fixed-fps 60 \
    --script res://tests/run_tests.gd >>"$log_path" 2>&1; then
    run_status=0
else
    run_status=$?
fi
cat "$log_path"

if (( run_status != 0 )); then
    printf 'Headless tests exited with status %s.\n' "$run_status" >&2
    exit "$run_status"
fi
if rg -q 'SCRIPT ERROR:|ERROR:' "$log_path"; then
    printf 'Godot reported an error during the headless tests.\n' >&2
    exit 1
fi
if ! rg -q '^CHECKS passed=[1-9][0-9]* failed=0$' "$log_path"; then
    printf 'The headless tests did not finish successfully.\n' >&2
    exit 1
fi
