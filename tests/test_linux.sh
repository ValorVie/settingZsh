#!/usr/bin/env bash
# =============================================================================
# Linux/WSL wrapper retire audit
# 驗證 setup_linux.sh / update_linux.sh 已退役為 no-write shim
# 使用方式：
#   bash tests/test_linux.sh
# =============================================================================

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

check_retired_shim() {
    local script_path="$1"
    local script_name="$2"

    echo "--- Audit: $script_name ---"
    if [ ! -f "$script_path" ]; then
        fail "$script_name 不存在"
        return
    fi

    if grep -qiE 'retired|deprecated' "$script_path"; then
        pass "$script_name 包含退役提示"
    else
        fail "$script_name 缺少退役提示"
    fi

    if grep -q 'chezmoi init --apply' "$script_path" && grep -q 'chezmoi update' "$script_path"; then
        pass "$script_name 明確提示使用 chezmoi init --apply / chezmoi update"
    else
        fail "$script_name 未明確提示新的 chezmoi 入口"
    fi

    if grep -q '此入口不再執行任何寫檔流程' "$script_path"; then
        pass "$script_name 明確聲明不做寫檔"
    else
        fail "$script_name 缺少 no-write 聲明"
    fi

    if grep -q 'chezmoi -S' "$script_path" || grep -q 'apply --init --force' "$script_path" || grep -q 'python -m settingzsh\.cli' "$script_path"; then
        fail "$script_name 仍包含舊的寫入入口"
    else
        pass "$script_name 不包含舊的寫入入口"
    fi
}

echo "=== Linux/WSL wrapper retire audit ==="
echo "Date: $(date)"
echo ""

check_retired_shim "$PROJECT_DIR/setup_linux.sh" "setup_linux.sh"
check_retired_shim "$PROJECT_DIR/update_linux.sh" "update_linux.sh"

echo ""
echo "==============================="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "==============================="
if [ "$FAIL" -gt 0 ]; then
    echo "  Result: FAILED"
    exit 1
fi

echo "  Result: PASSED"
