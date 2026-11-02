#!/usr/bin/env bash
# Exporta a build Web (sem threads, roda em qualquer hospedagem estática, ex.: GitHub Pages).
set -euo pipefail
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
mkdir -p build/web
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
ls -la build/web
