#!/usr/bin/env bash
# 安裝後 Neovim runtime acceptance。唯讀檢查，不安裝或更新任何 package。

set -euo pipefail

if [[ "${1:-}" != "--run" ]]; then
    printf '此腳本只做 opt-in runtime 驗收。確認已完成安裝後執行：%s --run\n' "$0"
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLING_FILE="$PROJECT_DIR/nvim/lua/config/tooling.lua"
SOURCE_FIXTURE_DIR="$PROJECT_DIR/tests/fixtures/nvim-runtime"
MASON_BIN="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/bin"
MASON_ROOT="${MASON_BIN%/bin}"

RUNTIME_FIXTURE_DIR="$(mktemp -d /tmp/settingzsh-nvim-accept.XXXXXXXX)"
case "$RUNTIME_FIXTURE_DIR" in
    /tmp/settingzsh-nvim-accept.*) ;;
    *)
        printf 'BLOCKING unexpected runtime fixture path: %s\n' "$RUNTIME_FIXTURE_DIR" >&2
        exit 1
        ;;
esac
cleanup_runtime_fixture() {
    rm -rf -- "$RUNTIME_FIXTURE_DIR"
}
trap cleanup_runtime_fixture EXIT
cp -R "$SOURCE_FIXTURE_DIR/." "$RUNTIME_FIXTURE_DIR/"
mkdir -p "$RUNTIME_FIXTURE_DIR/.git"

for dependency in nvim git; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'BLOCKING missing command: %s\n' "$dependency" >&2
        exit 1
    fi
done

printf '%s\n' '=== LazyVim runtime ==='
nvim --headless -i NONE \
    "+lua local ok,c=pcall(require,'lazy.core.config'); if not ok then io.stderr:write('BLOCKING LazyVim not loaded\\n'); os.exit(1) end; io.stdout:write(('plugins=%d picker=%s\\n'):format(vim.tbl_count(c.plugins), LazyVim.pick.picker.name))" \
    +qa

printf '%s\n' '=== P0 executables ==='
missing=0
while IFS='|' read -r category name package command_name; do
    command_path="$(command -v "$command_name" 2>/dev/null || true)"
    if [[ -z "$command_path" && -x "$MASON_BIN/$command_name" ]]; then
        command_path="$MASON_BIN/$command_name"
    fi
    if [[ -n "$command_path" ]]; then
        receipt="$MASON_ROOT/packages/$package/mason-receipt.json"
        package_source="unavailable"
        if [[ -f "$receipt" ]] && command -v jq >/dev/null 2>&1; then
            package_source="$(jq -r '.source.id // "unavailable"' "$receipt")"
        fi
        printf 'PASS %s | %s | %s | %s | %s\n' \
            "$category" "$name" "$package" "$command_path" "$package_source"
    else
        printf 'BLOCKING %s | %s | Mason package %s | command %s\n' \
            "$category" "$name" "$package" "$command_name" >&2
        missing=$((missing + 1))
    fi
done < <(
    nvim --headless -u NONE -i NONE \
        "+lua local t=dofile('$TOOLING_FILE'); for category,items in pairs(t) do for _,item in ipairs(items) do io.stdout:write(('%s|%s|%s|%s\\n'):format(category,item.name,item.mason,item.command)) end end" \
        +qa
)

registry_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/registries/github/mason-org/mason-registry"
if [[ -d "$registry_dir/.git" ]]; then
    printf 'mason_registry_revision=%s\n' "$(git -C "$registry_dir" rev-parse HEAD)"
else
    printf '%s\n' 'mason_registry_revision=unavailable'
fi

if (( missing > 0 )); then
    printf 'BLOCKING missing_executables=%d\n' "$missing" >&2
    exit 1
fi

printf '%s\n' '=== Representative LSP attach ==='
lsp_failures=0
while IFS='|' read -r relative_file expected; do
    file="$RUNTIME_FIXTURE_DIR/$relative_file"
    raw_output="$(
        nvim --headless -i NONE "$file" \
            "+sleep 4000m" \
            "+lua local names={}; for _,client in ipairs(vim.lsp.get_clients({bufnr=0})) do table.insert(names,client.name) end; table.sort(names); io.stdout:write('__CLIENTS__='..table.concat(names,',')..'\\n')" \
            +qa 2>&1
    )"
    client_output="$(printf '%s\n' "$raw_output" | sed -n 's/^__CLIENTS__=//p' | tail -n 1)"
    missing_client=0
    IFS=',' read -r -a expected_clients <<< "$expected"
    for client in "${expected_clients[@]}"; do
        if [[ ",$client_output," != *",$client,"* ]]; then
            missing_client=1
        fi
    done
    if (( missing_client == 0 )); then
        printf 'PASS %s | %s\n' "$relative_file" "$client_output"
    else
        printf 'BLOCKING %s | expected %s | active %s | output %s\n' \
            "$relative_file" "$expected" "$client_output" "$raw_output" >&2
        lsp_failures=$((lsp_failures + 1))
    fi
done <<'EOF'
index.php|intelephense
main.py|pyright,ruff
main.ts|vtsls
config.json|jsonls
config.yaml|yamlls
Dockerfile|dockerls
compose.yaml|docker_compose_language_service
README.md|marksman
index.html|html
style.css|cssls
src/main.rs|rust-analyzer
EOF

if (( lsp_failures > 0 )); then
    printf 'BLOCKING lsp_attach_failures=%d\n' "$lsp_failures" >&2
    exit 1
fi

printf '%s\n' 'Executable and LSP attach gates passed. Continue with manual OSC 52 copy/paste and browser preview checks.'
