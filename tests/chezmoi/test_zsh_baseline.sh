#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

require_file() {
    local path="$1"
    if [ ! -f "$path" ]; then
        echo "missing file: $path"
        exit 1
    fi
}

require_contains() {
    local path="$1"
    local pattern="$2"
    local message="$3"
    if ! rg -Fq "$pattern" "$path"; then
        echo "$message"
        exit 1
    fi
}

require_file "home/dot_config/settingzsh/init.zsh.tmpl"
require_file "home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl"
require_file "home/dot_config/settingzsh/managed.d/40-editor.zsh.tmpl"
require_file "templates/zshrc_base_mac.zsh"
require_file "templates/zshrc_base_linux.zsh"
require_file "templates/zshrc_editor.zsh"

require_contains "home/dot_config/settingzsh/init.zsh.tmpl" "SETTINGZSH_LOADED" "init loader missing session guard"
require_contains "home/dot_config/settingzsh/init.zsh.tmpl" "managed.d/*.zsh(N)" "init loader missing managed fragments loop"
require_contains "home/dot_config/settingzsh/init.zsh.tmpl" "local.d/*.zsh(N)" "init loader missing local fragments loop"

require_contains "home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl" "typeset -U path fpath" "base fragment missing path/fpath dedupe"
require_contains "home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl" "/root/.local/bin" "base fragment missing linux root path behavior"
require_contains "home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl" "/home/\$(whoami)/.local/bin" "base fragment missing linux non-root path behavior"

for pattern in \
    'romkatv/powerlevel10k' \
    'zsh-users/zsh-completions' \
    'Aloxaf/fzf-tab' \
    'zsh-users/zsh-syntax-highlighting' \
    'zsh-users/zsh-autosuggestions' \
    'zsh-users/zsh-history-substring-search' \
    'djui/alias-tips' \
    'zoxide init --cmd cd zsh' \
    '.fzf.zsh' \
    '.p10k.zsh'
do
    require_contains "home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl" "$pattern" "base fragment missing $pattern"
done

compinit_count="$(rg -n 'compinit' home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl | wc -l | tr -d ' ')"
if [ "$compinit_count" -ne 1 ]; then
    echo "base fragment should initialize compinit exactly once"
    exit 1
fi

if rg -q '^precmd[[:space:]]*\(\)' home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl; then
    echo "base fragment should not override precmd() directly"
    exit 1
fi
require_contains "home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl" "precmd_functions+=(_settingzsh_emit_currentdir)" "base fragment missing named current-dir hook"

if rg -q -e 'brew shellenv|git clone|curl |wget |apt install|brew install' home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl; then
    echo "base fragment contains installer/network/bootstrap logic"
    exit 1
fi

if rg -q -e 'nvm\(\)|lazy_nvm|nvm.sh' home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl; then
    echo "editor integration leaked into base fragment"
    exit 1
fi

require_contains "home/dot_config/settingzsh/managed.d/40-editor.zsh.tmpl" "nvm" "editor fragment missing nvm integration placeholder"
require_contains "home/dot_config/settingzsh/managed.d/40-editor.zsh.tmpl" "SETTINGZSH_DISABLE_EDITOR_SHELL" "editor fragment missing feature flag guard"
require_contains "home/dot_config/settingzsh/managed.d/40-editor.zsh.tmpl" "lazy_nvm()" "editor fragment missing lazy_nvm helper"
require_contains "templates/zshrc_editor.zsh" "SETTINGZSH_DISABLE_EDITOR_SHELL" "legacy editor template missing feature flag guard"
require_contains "templates/zshrc_editor.zsh" "lazy_nvm()" "legacy editor template missing lazy_nvm helper"

for tpl in templates/zshrc_base_mac.zsh templates/zshrc_base_linux.zsh; do
    require_contains "$tpl" "managed fragment template" "legacy zsh template missing managed-fragment role marker"
    if rg -q -e '# -----------------------------|brew shellenv|git clone' "$tpl"; then
        echo "legacy template still includes full-file/installer behavior: $tpl"
        exit 1
    fi
done

if rg -q -e '# -----------------------------' templates/zshrc_editor.zsh; then
    echo "legacy editor template still looks like full-file shell content"
    exit 1
fi

echo "task3 zsh baseline checks: ok"
