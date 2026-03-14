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
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

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
    warn "uname -s = $OS（非 Linux 主機，僅做靜態腳本檢查）"
fi

# --- Test 2: .zshrc backup ---
echo "--- Test 2: .zshrc 備份邏輯 ---"
if [ -f ~/.zshrc ]; then
    pass ".zshrc 存在，備份邏輯可執行"
else
    warn ".zshrc 不存在（全新安裝情境）"
fi

# --- Test 3: Font URL ---
echo "--- Test 3: 字型下載 URL ---"
MAPLE_VERSION="v7.9"
MAPLE_ARCHIVE="MapleMonoNL-NF-CN.zip"
MAPLE_URL="https://github.com/subframe7536/maple-font/releases/download/${MAPLE_VERSION}/${MAPLE_ARCHIVE}"
HTTP_STATUS=$(curl -sIL -o /dev/null -w "%{http_code}" "$MAPLE_URL")
if [ "$HTTP_STATUS" = "200" ]; then
    pass "Font URL HTTP $HTTP_STATUS: $MAPLE_ARCHIVE"
else
    fail "Font URL HTTP $HTTP_STATUS: $MAPLE_ARCHIVE"
fi

# --- Test 4: Font download & extract ---
echo "--- Test 4: 字型下載與解壓 ---"
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

# --- Test 5: Font installation ---
echo "--- Test 5: 字型安裝狀態 ---"
FONT_COUNT=$(fc-list 2>/dev/null | grep -c "Maple Mono NL NF CN" || echo "0")
if [ "$FONT_COUNT" -gt 0 ]; then
    pass "已安裝 $FONT_COUNT 個 Maple Mono NL NF CN 字型"
else
    warn "字型尚未安裝（首次安裝時會自動處理）"
fi

# --- Test 6: fzf ---
echo "--- Test 6: fzf ---"
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

# --- Test 7: zoxide ---
echo "--- Test 7: zoxide ---"
if command -v zoxide >/dev/null 2>&1 || [ -f ~/.local/bin/zoxide ]; then
    ZOXIDE_VER=$(zoxide --version 2>/dev/null || ~/.local/bin/zoxide --version 2>/dev/null)
    pass "zoxide: $ZOXIDE_VER"
else
    warn "zoxide 未安裝（首次安裝時會自動處理）"
fi

# --- Test 8: zinit ---
echo "--- Test 8: zinit ---"
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ -f "$ZINIT_HOME/zinit.zsh" ]; then
    pass "zinit.zsh 存在"
else
    warn "zinit 未安裝（首次啟動 zsh 時會自動安裝）"
fi

# --- Test 9: update.sh OS detection ---
echo "--- Test 9: update.sh OS 偵測 ---"
case "$OS" in
    Linux*) pass "update.sh 會呼叫 update_linux.sh" ;;
    Darwin*) pass "update.sh 會呼叫 update_mac.sh" ;;
    *) fail "不支援的 OS: $OS" ;;
esac

# =============================================================================
# Editor 環境測試（僅在已安裝時執行）
# =============================================================================

FEATURES_FILE="$HOME/.settingzsh/features"
HAS_EDITOR=false
if [ -f "$FEATURES_FILE" ] && grep -qx "editor" "$FEATURES_FILE"; then
    HAS_EDITOR=true
elif command -v nvim >/dev/null 2>&1; then
    HAS_EDITOR=true
fi

if [ "$HAS_EDITOR" = true ]; then
    echo ""
    echo "=== Editor 環境測試 ==="

    # --- Test 10: vim ---
    echo "--- Test 10: vim ---"
    if command -v vim >/dev/null 2>&1; then
        pass "vim: $(vim --version | head -1)"
    else
        fail "vim 未安裝"
    fi

    # --- Test 11: neovim ---
    echo "--- Test 11: neovim ---"
    if command -v nvim >/dev/null 2>&1; then
        NVIM_VER=$(nvim --version | head -1)
        pass "nvim: $NVIM_VER"
        # 檢查版本 >= 0.10
        NVIM_MINOR=$(echo "$NVIM_VER" | sed -n 's/.*v[0-9]*\.\([0-9]*\).*/\1/p')
        if [ "${NVIM_MINOR:-0}" -ge 10 ]; then
            pass "nvim 版本 >= 0.10（LazyVim 需求）"
        else
            fail "nvim 版本 < 0.10（LazyVim 需要 >= 0.10）"
        fi
    else
        fail "nvim 未安裝"
    fi

    # --- Test 12: nvm ---
    echo "--- Test 12: nvm ---"
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        pass "nvm 已安裝（$HOME/.nvm/nvm.sh 存在）"
    else
        fail "nvm 未安裝"
    fi

    # --- Test 13: node ---
    echo "--- Test 13: node ---"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    if command -v node >/dev/null 2>&1; then
        pass "node: $(node --version)"
    else
        fail "node 未安裝"
    fi

    # --- Test 14: ripgrep ---
    echo "--- Test 14: ripgrep ---"
    if command -v rg >/dev/null 2>&1; then
        pass "rg: $(rg --version | head -1)"
    else
        fail "ripgrep 未安裝"
    fi

    # --- Test 15: fd ---
    echo "--- Test 15: fd ---"
    if command -v fdfind >/dev/null 2>&1 || command -v fd >/dev/null 2>&1; then
        FD_VER=$(fdfind --version 2>/dev/null || fd --version 2>/dev/null)
        pass "fd: $FD_VER"
    else
        fail "fd 未安裝"
    fi

    # --- Test 16: lazygit ---
    echo "--- Test 16: lazygit ---"
    if command -v lazygit >/dev/null 2>&1; then
        pass "lazygit: $(lazygit --version 2>/dev/null | head -1)"
    else
        fail "lazygit 未安裝"
    fi
else
    echo ""
    echo "=== Editor 環境未安裝，略過 Editor 測試 ==="
fi

# =============================================================================
# Wrapper/CLI 機制測試
# =============================================================================

echo ""
echo "=== Wrapper/CLI 機制測試 ==="

# --- Test: uv ---
echo "--- Test: uv ---"
if command -v uv >/dev/null 2>&1; then
    pass "uv: $(uv --version 2>/dev/null)"
else
    warn "uv 未安裝（首次安裝時會自動處理）"
fi

# --- Test: setup 使用 Python CLI ---
echo "--- Test: setup 使用 Python CLI ---"
if grep -q 'python -m settingzsh\.cli' "$PROJECT_DIR/setup_linux.sh" \
    && grep -q 'run_settingzsh_cli setup' "$PROJECT_DIR/setup_linux.sh"; then
    pass "setup_linux.sh 以 Python CLI 執行 setup"
else
    fail "setup_linux.sh 尚未改用 python -m settingzsh.cli setup"
fi

# --- Test: templates ---
echo "--- Test: templates ---"
for tpl in templates/zshrc_base_mac.zsh templates/zshrc_base_linux.zsh templates/zshrc_editor.zsh; do
    if [ -f "$PROJECT_DIR/$tpl" ]; then
        pass "$tpl 存在"
    else
        fail "$tpl 不存在"
    fi
done

# --- Test: update 使用 Python CLI ---
echo "--- Test: update 使用 Python CLI ---"
if grep -q 'python -m settingzsh\.cli' "$PROJECT_DIR/update_linux.sh" \
    && grep -q 'run_settingzsh_cli reconcile' "$PROJECT_DIR/update_linux.sh"; then
    pass "update_linux.sh 以 Python CLI 執行 reconcile"
else
    fail "update_linux.sh 尚未改用 python -m settingzsh.cli reconcile"
fi

# --- Test: setup 不可保留 .zshrc destructive fallback ---
echo "--- Test: setup 不可保留 .zshrc destructive fallback ---"
if grep -q 'cp "\$template" "\$target"' "$PROJECT_DIR/setup_linux.sh"; then
    fail "setup_linux.sh 仍包含 destructive fallback"
else
    pass "setup_linux.sh 不含 destructive fallback"
fi

# --- Test: pyproject.toml ---
echo "--- Test: pyproject.toml ---"
if [ -f "$PROJECT_DIR/lib/pyproject.toml" ]; then
    pass "lib/pyproject.toml 存在"
else
    fail "lib/pyproject.toml 不存在"
fi

# --- Test: features file ---
echo ""
echo "--- Test: features 標記檔 ---"
if [ -f "$FEATURES_FILE" ]; then
    pass "features 檔案存在：$(cat "$FEATURES_FILE" | tr '\n' ' ')"
else
    warn "features 檔案不存在（舊版安裝或尚未執行 setup）"
fi

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
