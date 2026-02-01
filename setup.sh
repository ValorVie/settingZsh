#!/usr/bin/env bash
#
# Unix 統一入口：偵測 OS 後呼叫對應平台的安裝腳本
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

case "$OS" in
    Linux*)
        echo "=== 偵測到 Linux 環境 ==="
        bash "$SCRIPT_DIR/setup_linux.sh"
        ;;
    Darwin*)
        echo "=== 偵測到 macOS 環境 ==="
        bash "$SCRIPT_DIR/setup_mac.sh"
        ;;
    *)
        echo "錯誤：不支援的作業系統「$OS」。此腳本僅支援 Linux 與 macOS。" >&2
        exit 1
        ;;
esac
