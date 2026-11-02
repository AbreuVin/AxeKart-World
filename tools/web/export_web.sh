#!/usr/bin/env bash
# Exporta a build Web (sem threads, roda em qualquer hospedagem estática, ex.: GitHub Pages).
set -euo pipefail
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
mkdir -p build/web
if "$GODOT" --headless --path . --import 2>&1 | grep -E "SCRIPT ERROR|Parse Error"; then
  echo "Erro de script: corrija antes de exportar." >&2
  exit 1
fi
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
ls -la build/web
