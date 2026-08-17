#!/usr/bin/env bash
# 無網路 Neovim 配置 gate；不安裝外掛或修改真實使用者配置。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

for dependency in uv nvim; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf '缺少必要指令：%s\n' "$dependency" >&2
        exit 1
    fi
done

cd "$PROJECT_DIR"
UV_OFFLINE=1 uv run --offline --no-project --with pytest \
    pytest -q tests/test_nvim_*.py
