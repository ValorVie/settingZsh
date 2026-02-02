#!/usr/bin/env bash
# =============================================================================
# macOS 環境測試腳本
# 測試 setup_mac.sh / update_mac.sh 的各項功能
# 使用方式：在 macOS 環境中執行
#   bash tests/test_mac.sh
# =============================================================================

PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }

echo "=== macOS 環境測試 ==="
echo "Date: $(date)"
echo "OS: $(uname -s) $(uname -r)"
echo ""

# --- Test 1: OS detection ---
echo "--- Test 1: OS 偵測 ---"
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
    pass "uname -s = Darwin"
else
    fail "uname -s = $OS (expected Darwin)"
fi

# --- Test 2: Homebrew ---
echo "--- Test 2: Homebrew ---"
if command -v brew >/dev/null 2>&1; then
    pass "brew available"
else
    fail "brew NOT found"
fi

# --- Test 3: .zshrc backup ---
echo "--- Test 3: .zshrc 備份邏輯 ---"
if [ -f ~/.zshrc ]; then
    pass ".zshrc 存在，備份邏輯可執行"
else
    warn ".zshrc 不存在（全新安裝情境）"
fi

# --- Test 4: Source .zshrc ---
echo "--- Test 4: Source .zshrc ---"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_ZSHRC="$SCRIPT_DIR/.zshrc"
if [ -f "$SOURCE_ZSHRC" ]; then
    if grep -q 'C:/Users/' "$SOURCE_ZSHRC" 2>/dev/null; then
        fail ".zshrc 包含 Windows 路徑"
    else
        pass ".zshrc 使用動態路徑"
    fi
else
    warn "專案 .zshrc 不存在（由 setup 腳本動態產生）"
fi

# --- Test 5: Font URL ---
echo "--- Test 5: 字型下載 URL ---"
MAPLE_VERSION="v7.9"
MAPLE_ARCHIVE="MapleMonoNL-NF-CN.zip"
MAPLE_URL="https://github.com/subframe7536/maple-font/releases/download/${MAPLE_VERSION}/${MAPLE_ARCHIVE}"
HTTP_STATUS=$(curl -sIL -o /dev/null -w "%{http_code}" "$MAPLE_URL")
if [ "$HTTP_STATUS" = "200" ]; then
    pass "Font URL HTTP $HTTP_STATUS: $MAPLE_ARCHIVE"
else
    fail "Font URL HTTP $HTTP_STATUS: $MAPLE_ARCHIVE"
fi

# --- Test 6: Font installation ---
echo "--- Test 6: 字型安裝狀態 ---"
if [ -d ~/Library/Fonts ]; then
    FONT_COUNT=$(ls ~/Library/Fonts/*Maple* 2>/dev/null | wc -l | tr -d ' ')
    if [ "$FONT_COUNT" -gt 0 ]; then
        pass "已安裝 $FONT_COUNT 個 Maple Mono 字型檔"
    else
        warn "~/Library/Fonts 中無 Maple Mono 字型（首次安裝時會自動處理）"
    fi
else
    warn "~/Library/Fonts 不存在"
fi

# --- Test 7: fzf ---
echo "--- Test 7: fzf ---"
if command -v fzf >/dev/null 2>&1; then
    pass "fzf: $(fzf --version 2>/dev/null | head -1)"
elif [ -d ~/.fzf ]; then
    pass "~/.fzf 存在（fzf 已 clone）"
else
    warn "fzf 未安裝（首次安裝時會自動處理）"
fi

# --- Test 8: zoxide ---
echo "--- Test 8: zoxide ---"
if command -v zoxide >/dev/null 2>&1; then
    pass "zoxide: $(zoxide --version 2>/dev/null)"
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

# --- Test 10: setup_mac.sh font archive name ---
echo "--- Test 10: setup_mac.sh 字型檔名 ---"
SETUP_SCRIPT="$SCRIPT_DIR/setup_mac.sh"
if [ -f "$SETUP_SCRIPT" ]; then
    if grep -q 'MapleMonoNL-NF-CN\.zip' "$SETUP_SCRIPT"; then
        pass "setup_mac.sh uses correct archive name"
    else
        fail "setup_mac.sh has wrong archive name"
    fi
else
    fail "setup_mac.sh 不存在"
fi

# --- Test 11: update_mac.sh font archive name ---
echo "--- Test 11: update_mac.sh 字型檔名 ---"
UPDATE_SCRIPT="$SCRIPT_DIR/update_mac.sh"
if [ -f "$UPDATE_SCRIPT" ]; then
    if grep -q 'MapleMonoNL-NF-CN\.zip' "$UPDATE_SCRIPT"; then
        pass "update_mac.sh uses correct archive name"
    else
        fail "update_mac.sh has wrong archive name"
    fi
else
    fail "update_mac.sh 不存在"
fi

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

    # --- Test 12: vim ---
    echo "--- Test 12: vim ---"
    if command -v vim >/dev/null 2>&1; then
        pass "vim: $(vim --version | head -1)"
    else
        fail "vim 未安裝"
    fi

    # --- Test 13: neovim ---
    echo "--- Test 13: neovim ---"
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

    # --- Test 14: nvm ---
    echo "--- Test 14: nvm ---"
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        pass "nvm 已安裝（$HOME/.nvm/nvm.sh 存在）"
    else
        fail "nvm 未安裝"
    fi

    # --- Test 15: node ---
    echo "--- Test 15: node ---"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    if command -v node >/dev/null 2>&1; then
        pass "node: $(node --version)"
    else
        fail "node 未安裝"
    fi

    # --- Test 16: ripgrep ---
    echo "--- Test 16: ripgrep ---"
    if command -v rg >/dev/null 2>&1; then
        pass "rg: $(rg --version | head -1)"
    else
        fail "ripgrep 未安裝"
    fi

    # --- Test 17: fd ---
    echo "--- Test 17: fd ---"
    if command -v fd >/dev/null 2>&1; then
        pass "fd: $(fd --version 2>/dev/null)"
    else
        fail "fd 未安裝"
    fi

    # --- Test 18: lazygit ---
    echo "--- Test 18: lazygit ---"
    if command -v lazygit >/dev/null 2>&1; then
        pass "lazygit: $(lazygit --version 2>/dev/null | head -1)"
    else
        fail "lazygit 未安裝"
    fi

    # --- Test 19: nvim config ---
    echo "--- Test 19: Neovim 配置 ---"
    NVIM_CONFIG_DIR="$HOME/.config/nvim"
    if [ -f "$NVIM_CONFIG_DIR/init.lua" ]; then
        pass "nvim init.lua exists at $NVIM_CONFIG_DIR"
    else
        warn "nvim config not deployed yet"
    fi
else
    echo ""
    echo "=== Editor 環境未安裝，略過 Editor 測試 ==="
fi

# =============================================================================
# 合併機制測試
# =============================================================================

echo ""
echo "=== 合併機制測試 ==="

# --- Test: uv ---
echo "--- Test: uv ---"
if command -v uv >/dev/null 2>&1; then
    pass "uv: $(uv --version 2>/dev/null)"
else
    warn "uv 未安裝（首次安裝時會自動處理）"
fi

# --- Test: config_merge.py ---
echo "--- Test: config_merge.py ---"
if [ -f "$SCRIPT_DIR/lib/config_merge.py" ]; then
    pass "lib/config_merge.py 存在"
else
    fail "lib/config_merge.py 不存在"
fi

# --- Test: templates ---
echo "--- Test: templates ---"
TEMPLATES_OK=true
for tpl in templates/zshrc_base_mac.zsh templates/zshrc_base_linux.zsh templates/zshrc_editor.zsh; do
    if [ -f "$SCRIPT_DIR/$tpl" ]; then
        pass "$tpl 存在"
    else
        fail "$tpl 不存在"
        TEMPLATES_OK=false
    fi
done

# --- Test: merge_config 函式 ---
echo "--- Test: merge_config 函式 ---"
if grep -q 'merge_config()' "$SCRIPT_DIR/setup_mac.sh"; then
    pass "setup_mac.sh 包含 merge_config 函式"
else
    fail "setup_mac.sh 缺少 merge_config 函式"
fi

# --- Test: pyproject.toml ---
echo "--- Test: pyproject.toml ---"
if [ -f "$SCRIPT_DIR/lib/pyproject.toml" ]; then
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
