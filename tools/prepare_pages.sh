#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$project_dir/tools/export_web.sh"
mkdir -p "$project_dir/docs"
cp "$project_dir/builds/web/"* "$project_dir/docs/"
touch "$project_dir/docs/.nojekyll" "$project_dir/docs/.gdignore"
printf 'GitHub Pages files prepared in %s/docs (hosting is enabled separately).\n' "$project_dir"
