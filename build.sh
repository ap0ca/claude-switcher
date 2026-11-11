#!/usr/bin/env bash
# Build a standalone Linux binary of cswap into dist/cswap.
#   ./build.sh            build only
#   ./build.sh --install  build, then copy to ~/.local/bin/cswap
# Needs python3 (3.12+) with venv; downloads PyInstaller and dependencies from PyPI.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

python3 -m venv "$work/venv"
"$work/venv/bin/pip" install -q --upgrade pip
"$work/venv/bin/pip" install -q "$repo" "pyinstaller==6.22.3" "truststore==0.10.4"

# Entry script outside src/ so PyInstaller does not put the package directory on the import path.
printf 'from claude_swap.cli import main\nmain()\n' > "$work/cswap_entry.py"

"$work/venv/bin/pyinstaller" --noconfirm --clean --onefile --log-level WARN --name cswap \
  --distpath "$repo/dist" --workpath "$work/build" --specpath "$work" \
  --collect-all textual --collect-submodules rich --collect-data claude_swap \
  --copy-metadata claude-swap --copy-metadata textual \
  --exclude-module rumps --exclude-module AppKit --exclude-module tkinter \
  "$work/cswap_entry.py"

"$repo/dist/cswap" --version

if [[ "${1:-}" == "--install" ]]; then
  mkdir -p "$HOME/.local/bin"
  install -m 755 "$repo/dist/cswap" "$HOME/.local/bin/cswap"
  echo "Installed to $HOME/.local/bin/cswap"
fi
