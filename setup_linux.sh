#!/usr/bin/env bash
#
# 此腳本將在 Ubuntu/Debian 環境上安裝並設定 zsh + zinit + fzf + Maple Mono 字型等環境
# 選裝：vim + neovim (LazyVim) + nvm + node + ripgrep + fd + lazygit
# 使用方式：透過統一入口執行
#   chmod +x setup.sh
#   ./setup.sh
#
# 注意：chsh 預設會更改目前執行此腳本的使用者的 shell，如果需要更改其他使用者可再調整參數。

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NVM_VERSION="v0.40.1"
LAZYGIT_VERSION="0.44.1"
RIPGREP_VERSION="14.1.1"
FD_VERSION="10.2.0"

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

has_sudo() {
    sudo -n true 2>/dev/null
}

install_uv() {
    if command -v uv >/dev/null 2>&1; then
        echo "uv 已安裝，略過"
    else
        echo "=== 安裝 uv... ==="
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
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
    # 1. 安裝 uv
    install_uv

    # 2. 下載並安裝 Maple Mono NL NF CN
    echo "=== 安裝 Maple Mono NL NF CN... ==="
    MAPLE_VERSION="v7.9"
    MAPLE_ARCHIVE="MapleMonoNL-NF-CN.zip"
    curl -OL "https://github.com/subframe7536/maple-font/releases/download/${MAPLE_VERSION}/${MAPLE_ARCHIVE}"
    mkdir -p MapleMono
    unzip -o "${MAPLE_ARCHIVE}" -d MapleMono
    mkdir -p ~/.local/share/fonts/MapleMono
    mv MapleMono/*.ttf ~/.local/share/fonts/MapleMono/ 2>/dev/null || mv MapleMono/*.otf ~/.local/share/fonts/MapleMono/ 2>/dev/null || true
    fc-cache -fv
    rm -f "${MAPLE_ARCHIVE}"

    # 3. 建立補完檔案的快取資料夾
    mkdir -p ~/.cache/zinit/completions

    # 4. 安裝 fzf
    echo "=== 安裝 fzf... ==="
    if [ -d ~/.fzf ]; then
        echo "fzf 已存在，執行更新..."
        git -C ~/.fzf pull
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    fi
    ~/.fzf/install --all --key-bindings --completion --no-bash --no-fish

    # 5. 安裝 zoxide
    echo "=== 安裝 zoxide... ==="
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

    # 6. 合併 .zshrc（zsh 基本段）
    echo "=== 合併 zshrc 設定... ==="
    merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_base_linux.zsh" "zsh-base" "zsh"
}

# =============================================================================
# Editor 環境安裝
# =============================================================================

install_editor_env() {
    mkdir -p ~/.local/bin

    # 1. 安裝 build-essential, vim, ripgrep, fd
    echo "=== 安裝編輯器前置套件... ==="
    if has_sudo; then
        sudo apt install -y build-essential vim ripgrep fd-find
    else
        echo "無 sudo 權限，檢測已安裝的套件..."
        command -v gcc >/dev/null 2>&1 || echo "⚠️  缺少 gcc (build-essential)，treesitter 語法解析器可能無法編譯"
        command -v vim >/dev/null 2>&1 || echo "⚠️  缺少 vim（nvim 仍可正常使用）"
        # ripgrep fallback
        if ! command -v rg >/dev/null 2>&1; then
            echo "--- 下載 ripgrep binary ---"
            if curl -Lo /tmp/ripgrep.tar.gz "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
                && tar xzf /tmp/ripgrep.tar.gz -C /tmp \
                && install /tmp/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/rg ~/.local/bin/; then
                echo "ripgrep 已安裝至 ~/.local/bin/rg"
            else
                echo "⚠️  ripgrep 下載或安裝失敗，Telescope 全文搜尋可能無法使用"
            fi
            rm -rf /tmp/ripgrep.tar.gz /tmp/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl
        fi
        # fd fallback
        if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
            echo "--- 下載 fd binary ---"
            if curl -Lo /tmp/fd.tar.gz "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
                && tar xzf /tmp/fd.tar.gz -C /tmp \
                && install /tmp/fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd ~/.local/bin/; then
                echo "fd 已安裝至 ~/.local/bin/fd"
            else
                echo "⚠️  fd 下載或安裝失敗，Telescope 檔案搜尋可能退化"
            fi
            rm -rf /tmp/fd.tar.gz /tmp/fd-v${FD_VERSION}-x86_64-unknown-linux-musl
        fi
    fi

    # 2. 安裝 Neovim（從 GitHub Release）
    echo "=== 安裝 Neovim... ==="
    if command -v nvim >/dev/null 2>&1; then
        echo "Neovim 已安裝：$(nvim --version | head -1)"
    else
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        tar xzf nvim-linux-x86_64.tar.gz -C ~/.local --strip-components=1
        rm -f nvim-linux-x86_64.tar.gz
        echo "Neovim 已安裝至 ~/.local/bin/nvim"
    fi

    # 3. 安裝 lazygit（從 GitHub Release）
    echo "=== 安裝 lazygit... ==="
    if command -v lazygit >/dev/null 2>&1; then
        echo "lazygit 已安裝：$(lazygit --version)"
    else
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xzf lazygit.tar.gz lazygit
        install lazygit ~/.local/bin/
        rm -f lazygit lazygit.tar.gz
        echo "lazygit 已安裝至 ~/.local/bin/lazygit"
    fi

    # 檢測舊版系統安裝
    if [ -f /usr/local/bin/nvim ]; then
        echo ""
        echo "⚠️  偵測到舊版 Neovim 於 /usr/local/bin/nvim"
        echo "    版本：$(/usr/local/bin/nvim --version 2>/dev/null | head -1 || echo '未知')"
        echo "    此版本可能因 PATH 順序優先於新安裝的 ~/.local/bin/nvim"
        echo "    建議移除：sudo rm /usr/local/bin/nvim"
    fi
    if [ -f /usr/local/bin/lazygit ]; then
        echo ""
        echo "⚠️  偵測到舊版 lazygit 於 /usr/local/bin/lazygit"
        echo "    此版本可能因 PATH 順序優先於新安裝的 ~/.local/bin/lazygit"
        echo "    建議移除：sudo rm /usr/local/bin/lazygit"
    fi

    # 4. 安裝 nvm
    echo "=== 安裝 nvm... ==="
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        echo "nvm 已安裝，略過"
    else
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    fi

    # 載入 nvm 以便安裝 node
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # 5. 安裝 Node.js LTS
    echo "=== 安裝 Node.js LTS... ==="
    nvm install --lts
    nvm alias default lts/*

    # 6. 合併 .vimrc
    echo "=== 合併 Vim 配置... ==="
    merge_config ~/.vimrc "$SCRIPT_DIR/vim/.vimrc" "vimrc" "vim"

    # 7. 部署 Neovim 配置
    echo "=== 部署 Neovim 配置... ==="
    if [ -d ~/.config/nvim ]; then
        mv ~/.config/nvim ~/.config/nvim.bak
        echo "既有 nvim 配置已備份至 ~/.config/nvim.bak"
    fi
    mkdir -p ~/.config
    cp -r "$SCRIPT_DIR/nvim" ~/.config/nvim

    # 8. 合併 .zshrc editor 段
    echo "=== 合併 editor 設定至 .zshrc... ==="
    merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_editor.zsh" "editor" "zsh"
}

# =============================================================================
# 主流程
# =============================================================================

echo "══════════════════════════════════════"
echo "  settingZsh 環境安裝程式 (Linux)"
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
