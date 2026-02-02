#!/usr/bin/env bash
#
# 此腳本將在 macOS 環境上安裝並設定 zsh + zinit + fzf + Maple Mono 字型等環境
# 選裝：vim + neovim (LazyVim) + nvm + node + ripgrep + fd + lazygit
# 使用方式：在終端機執行
#   chmod +x setup_mac.sh
#   ./setup_mac.sh
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NVM_VERSION="v0.40.1"

# =============================================================================
# 共用函式
# =============================================================================

ask_yes_no() {
    local prompt="$1"
    local default="${2:-N}"
    local reply
    if [ "$default" = "Y" ]; then
        printf "%s (Y/n): " "$prompt"
    else
        printf "%s (y/N): " "$prompt"
    fi
    read -r reply
    reply="${reply:-$default}"
    case "$reply" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

save_features() {
    mkdir -p ~/.settingzsh
    printf "%s\n" "$@" > ~/.settingzsh/features
    echo "已記錄安裝模組至 ~/.settingzsh/features"
}

install_uv() {
    if command -v uv >/dev/null 2>&1; then
        echo "uv 已安裝，略過"
    else
        echo "=== 安裝 uv... ==="
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
}

merge_config() {
    local target="$1" template="$2" section="$3" filetype="$4"
    if command -v uv >/dev/null 2>&1; then
        uv run "$SCRIPT_DIR/lib/config_merge.py" \
            --target "$target" --template "$template" \
            --section "$section" --type "$filetype"
    else
        echo "[警告] uv 不可用，使用備份+覆寫模式"
        [ -f "$target" ] && cp "$target" "${target}.bak"
        cp "$template" "$target"
    fi
}

# =============================================================================
# Zsh 環境安裝
# =============================================================================

install_zsh_env() {
    # 1. 檢測 Homebrew
    echo "=== 檢測 Homebrew... ==="
    if ! command -v brew >/dev/null 2>&1; then
        echo "錯誤：未偵測到 Homebrew。請先安裝 Homebrew：" >&2
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >&2
        exit 1
    fi

    # 2. 安裝前置套件
    echo "=== 安裝前置套件... ==="
    brew install zsh git unzip xz

    # 3. 安裝 uv
    install_uv

    # 4. 下載並安裝 Maple Mono NL NF CN
    echo "=== 安裝 Maple Mono NL NF CN... ==="
    MAPLE_VERSION="v7.9"
    MAPLE_ARCHIVE="MapleMonoNL-NF-CN.zip"
    curl -OL "https://github.com/subframe7536/maple-font/releases/download/${MAPLE_VERSION}/${MAPLE_ARCHIVE}"
    mkdir -p MapleMono
    unzip -o "${MAPLE_ARCHIVE}" -d MapleMono
    mkdir -p ~/Library/Fonts
    cp MapleMono/*.ttf ~/Library/Fonts/ 2>/dev/null || cp MapleMono/*.otf ~/Library/Fonts/ 2>/dev/null || true
    rm -rf MapleMono
    rm -f "${MAPLE_ARCHIVE}"
    echo "字型已安裝至 ~/Library/Fonts/"

    # 5. 建立補完檔案的快取資料夾
    mkdir -p ~/.cache/zinit/completions

    # 6. 安裝 fzf
    echo "=== 安裝 fzf... ==="
    if [ -d ~/.fzf ]; then
        echo "fzf 已存在，執行更新..."
        git -C ~/.fzf pull
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    fi
    ~/.fzf/install --all --key-bindings --completion --no-bash --no-fish

    # 7. 安裝 zoxide
    echo "=== 安裝 zoxide... ==="
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

    # 8. 合併 .zshrc（zsh 基本段）
    echo "=== 合併 zshrc 設定... ==="
    merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_base_mac.zsh" "zsh-base" "zsh"
}

# =============================================================================
# Editor 環境安裝
# =============================================================================

install_editor_env() {
    # 1. 安裝 vim, neovim, ripgrep, fd, lazygit
    echo "=== 安裝編輯器工具... ==="
    brew install vim neovim ripgrep fd lazygit

    # 2. 安裝 nvm
    echo "=== 安裝 nvm... ==="
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        echo "nvm 已安裝，略過"
    else
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    fi

    # 載入 nvm 以便安裝 node
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # 3. 安裝 Node.js LTS
    echo "=== 安裝 Node.js LTS... ==="
    nvm install --lts
    nvm alias default lts/*

    # 4. 合併 .vimrc
    echo "=== 合併 Vim 配置... ==="
    merge_config ~/.vimrc "$SCRIPT_DIR/vim/.vimrc" "vimrc" "vim"

    # 5. 部署 Neovim 配置
    echo "=== 部署 Neovim 配置... ==="
    if [ -d ~/.config/nvim ]; then
        mv ~/.config/nvim ~/.config/nvim.bak
        echo "既有 nvim 配置已備份至 ~/.config/nvim.bak"
    fi
    mkdir -p ~/.config
    cp -r "$SCRIPT_DIR/nvim" ~/.config/nvim

    # 6. 合併 .zshrc editor 段
    echo "=== 合併 editor 設定至 .zshrc... ==="
    merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_editor.zsh" "editor" "zsh"
}

# =============================================================================
# 主流程
# =============================================================================

echo "══════════════════════════════════════"
echo "  settingZsh 環境安裝程式 (macOS)"
echo "══════════════════════════════════════"

# 永遠安裝 Zsh 環境
install_zsh_env
FEATURES="zsh"

# 詢問是否安裝 Editor 環境
echo ""
if ask_yes_no "是否安裝編輯器環境？(vim + neovim + nvm + node + ripgrep + fd + lazygit)" "N"; then
    install_editor_env
    FEATURES="zsh editor"
fi

# 記錄已安裝模組
# shellcheck disable=SC2086
save_features $FEATURES

echo ""
echo "=== 設定完成！若要使 Zsh 成為預設 shell，請重新登入或重新開啟終端機。 ==="
echo "=== 若要立即套用新設定，可直接執行：exec zsh ==="
