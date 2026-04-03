#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="${ROOT_DIR}/wails3-go"
APP_BIN="${APP_DIR}/bin/Construct2Game"

if [ -x "${APP_BIN}" ]; then
  exec "${APP_BIN}"
fi

if [ -x "${APP_DIR}/run-dev.command" ]; then
  exec "${APP_DIR}/run-dev.command"
fi

echo "找不到可启动的新版本程序。"
exit 1
