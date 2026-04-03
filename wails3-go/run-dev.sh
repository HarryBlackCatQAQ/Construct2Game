#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -d "frontend/node_modules" ]; then
  npm --prefix frontend install
fi

if command -v wails3 >/dev/null 2>&1; then
  WAILS_BIN="wails3"
elif [ -x "${HOME}/go/bin/wails3" ]; then
  WAILS_BIN="${HOME}/go/bin/wails3"
else
  echo "找不到 wails3，请先安装 Wails 3 CLI，或把 ~/go/bin 加到 PATH。"
  exit 1
fi

WAILS_DIR="$(cd "$(dirname "${WAILS_BIN}")" && pwd)"
export PATH="${WAILS_DIR}:${PATH}"

"${WAILS_BIN}" dev -config ./build/config.yml
