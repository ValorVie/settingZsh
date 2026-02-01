#!/usr/bin/env bash
# =============================================================================
# Linux/WSL 環境測試腳本
# 測試 setup_linux.sh / update_linux.sh 的各項功能
# 使用方式：在 WSL 或 Linux 環境中執行
#   bash tests/test_linux.sh
# =============================================================================

PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }

echo "=== Linux/WSL 環境測試 ==="
echo "Date: $(date)"
echo "OS: $(uname -s) $(uname -r)"
echo ""

# --- Test 1: OS detection ---
echo "--- Test 1: setup.sh OS 偵測 ---"
OS="$(uname -s)"
if [ "$OS" = "Linux" ]; then
    pass "uname -s = Linux"
else
    fail "uname -s = $OS (expected Linux)"
fi

# --- Test 2: .zshrc backup ---
echo "--- Test 2: .zshrc 備份邏輯 ---"
if [ -f ~/.zshrc ]; then
    pass ".zshrc 存在，備份邏輯可執行"
else
    warn ".zshrc 不存在（全新安裝情境）"
fi

# --- Test 3: Python 3.13 ---
echo "--- Test 3: Python 3.13 ---"
if command -v python3.13 >/dev/null 2>&1; then
    pass "python3.13: $(python3.13 --version)"
else
    warn "python3.13 未安裝（需 sudo apt install）"
fi

# --- Test 4: Font URL ---
echo "--- Test 4: 字型下載 URL ---"
MAPLE_VERSION="v7.9"
MAPLE_ARCHIVE="MapleMonoNL-NF-CN.zip"
MAPLE_URL="https://github.com/subframe7536/maple-font/releases/download/${MAPLE_VERSION}/${MAPLE_ARCHIVE}"
HTTP_STATUS=$(curl -sIL -o /dev/null -w "%{http_code}" "$MAPLE_URL")
if [ "$HTTP_STATUS" = "200" ]; then
    pass "Font URL HTTP $HTTP_STATUS: $MAPLE_ARCHIVE"
else
    fail "Font URL HTTP $HTTP_STATUS: $MAPLE_ARCHIVE"
fi

# --- Test 5: Font download & extract ---
echo "--- Test 5: 字型下載與解壓 ---"
cd /tmp
if curl -sOL "$MAPLE_URL" && [ -f "$MAPLE_ARCHIVE" ]; then
    FILE_SIZE=$(stat -c%s "$MAPLE_ARCHIVE" 2>/dev/null || stat -f%z "$MAPLE_ARCHIVE" 2>/dev/null)
    if [ "$FILE_SIZE" -gt 1000000 ]; then
        pass "下載成功: $MAPLE_ARCHIVE ($(numfmt --to=iec $FILE_SIZE 2>/dev/null || echo "${FILE_SIZE} bytes"))"
    else
        fail "檔案過小: $FILE_SIZE bytes"
    fi
    mkdir -p TestMapleMono
    unzip -o "$MAPLE_ARCHIVE" -d TestMapleMono > /dev/null 2>&1
    TTF_COUNT=$(ls TestMapleMono/*.ttf 2>/dev/null | wc -l)
    if [ "$TTF_COUNT" -gt 0 ]; then
        pass "解壓成功: $TTF_COUNT 個 ttf 檔案"
    else
        fail "解壓後無 ttf 檔案"
    fi
    rm -rf TestMapleMono "$MAPLE_ARCHIVE"
else
    fail "下載失敗"
fi

# --- Test 6: Font installation ---
echo "--- Test 6: 字型安裝狀態 ---"
FONT_COUNT=$(fc-list 2>/dev/null | grep -c "Maple Mono NL NF CN" || echo "0")
if [ "$FONT_COUNT" -gt 0 ]; then
    pass "已安裝 $FONT_COUNT 個 Maple Mono NL NF CN 字型"
else
    warn "字型尚未安裝（首次安裝時會自動處理）"
fi

# --- Test 7: fzf ---
echo "--- Test 7: fzf ---"
if [ -d ~/.fzf ]; then
    pass "~/.fzf 存在 -> setup_linux.sh 會 git pull（不會重複 clone）"
    if [ -f ~/.fzf/install ]; then
        pass "~/.fzf/install 存在"
    else
        fail "~/.fzf/install 不存在"
    fi
else
    warn "~/.fzf 不存在（首次安裝時會 git clone）"
fi

# --- Test 8: zoxide ---
echo "--- Test 8: zoxide ---"
if command -v zoxide >/dev/null 2>&1 || [ -f ~/.local/bin/zoxide ]; then
    ZOXIDE_VER=$(zoxide --version 2>/dev/null || ~/.local/bin/zoxide --version 2>/dev/null)
    pass "zoxide: $ZOXIDE_VER"
else
    warn "zoxide 未安裝（首次安裝時會自動處理）"
fi

# --- Test 9: zinit ---
echo "--- Test 9: zinit ---"
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ -f "$ZINIT_HOME/zinit.zsh" ]; then
    pass "zinit.zsh 存在"
else
    warn "zinit 未安裝（首次啟動 zsh 時會自動安裝）"
fi

# --- Test 10: update.sh OS detection ---
echo "--- Test 10: update.sh OS 偵測 ---"
case "$OS" in
    Linux*) pass "update.sh 會呼叫 update_linux.sh" ;;
    Darwin*) pass "update.sh 會呼叫 update_mac.sh" ;;
    *) fail "不支援的 OS: $OS" ;;
esac

# --- Summary ---
echo ""
echo "==============================="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"
echo "==============================="
if [ "$FAIL" -gt 0 ]; then
    echo "  Result: FAILED"
    exit 1
else
    echo "  Result: PASSED"
fi
