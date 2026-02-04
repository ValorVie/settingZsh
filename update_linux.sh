#!/usr/bin/env bash
# Linux 環境更新已安裝的工具與套件
# 根據 ~/.settingzsh/features 決定更新範圍
set -e

FEATURES_FILE="$HOME/.settingzsh/features"
LAZYGIT_VERSION="0.44.1"
RIPGREP_VERSION="14.1.1"
FD_VERSION="10.2.0"

has_sudo() {
    sudo -n true 2>/dev/null
}

# 讀取已安裝模組
has_feature() {
    local feature="$1"
    if [ -f "$FEATURES_FILE" ]; then
        grep -qx "$feature" "$FEATURES_FILE"
    elif [ "$feature" = "editor" ]; then
        # fallback：偵測 nvim 是否存在
        command -v nvim >/dev/null 2>&1
    else
        return 0  # zsh 永遠更新
    fi
}

# =============================================================================
# Zsh 環境更新（永遠執行）
# =============================================================================

echo "=== 更新系統套件 ==="
sudo apt update -y
sudo apt upgrade -y

if [ -d "$HOME/.fzf" ]; then
    echo "=== 更新 fzf ==="
    git -C "$HOME/.fzf" pull
    "$HOME/.fzf/install" --all --key-bindings --completion --no-bash --no-fish
else
    echo "fzf 尚未安裝，略過更新"
fi

echo "=== 更新 zoxide ==="
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

if command -v zsh >/dev/null 2>&1; then
    echo "=== 更新 Zinit 及其插件 ==="
    ZINIT_HOME="${ZINIT_HOME:-${HOME}/.local/share/zinit/zinit.git}"
    zsh -i -c "source ${ZINIT_HOME}/zinit.zsh && zinit self-update && zinit update --all"
else
    echo "Zsh 尚未安裝，略過 Zinit 更新"
fi

echo "=== 下載最新 Maple Mono NL NF CN ==="
MAPLE_VERSION="v7.9"
MAPLE_ARCHIVE="MapleMonoNL-NF-CN.zip"
curl -OL "https://github.com/subframe7536/maple-font/releases/download/${MAPLE_VERSION}/${MAPLE_ARCHIVE}"
mkdir -p MapleMono
rm -rf MapleMono/*
unzip -o "${MAPLE_ARCHIVE}" -d MapleMono
mkdir -p "$HOME/.local/share/fonts/MapleMono"
mv MapleMono/*.ttf "$HOME/.local/share/fonts/MapleMono/" 2>/dev/null || mv MapleMono/*.otf "$HOME/.local/share/fonts/MapleMono/" 2>/dev/null || true
fc-cache -fv
rm -f "${MAPLE_ARCHIVE}"

# =============================================================================
# Editor 環境更新（僅在已安裝時執行）
# =============================================================================

if has_feature "editor"; then
    echo ""
    echo "=== 更新 Editor 環境 ==="

    mkdir -p ~/.local/bin

    # 更新 Neovim（重新下載最新版）
    echo "--- 更新 Neovim ---"
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    tar xzf nvim-linux-x86_64.tar.gz -C ~/.local --strip-components=1
    rm -f nvim-linux-x86_64.tar.gz

    # 更新 ripgrep, fd
    if has_sudo; then
        echo "--- 更新 ripgrep, fd-find (apt) ---"
        sudo apt install -y --only-upgrade ripgrep fd-find 2>/dev/null || true
    else
        echo "--- 更新 ripgrep, fd (binary) ---"
        if curl -Lo /tmp/ripgrep.tar.gz "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
            && tar xzf /tmp/ripgrep.tar.gz -C /tmp \
            && install /tmp/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/rg ~/.local/bin/; then
            echo "ripgrep 已更新"
        else
            echo "⚠️  ripgrep 下載或安裝失敗"
        fi
        rm -rf /tmp/ripgrep.tar.gz /tmp/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl

        if curl -Lo /tmp/fd.tar.gz "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
            && tar xzf /tmp/fd.tar.gz -C /tmp \
            && install /tmp/fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd ~/.local/bin/; then
            echo "fd 已更新"
        else
            echo "⚠️  fd 下載或安裝失敗"
        fi
        rm -rf /tmp/fd.tar.gz /tmp/fd-v${FD_VERSION}-x86_64-unknown-linux-musl
    fi

    # 更新 lazygit（重新下載最新版）
    echo "--- 更新 lazygit ---"
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xzf lazygit.tar.gz lazygit
    install lazygit ~/.local/bin/
    rm -f lazygit lazygit.tar.gz

    # 更新 nvm
    echo "--- 更新 nvm ---"
    NVM_VERSION="v0.40.1"
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    fi

    # 更新 Node.js LTS
    echo "--- 更新 Node.js LTS ---"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    if command -v nvm >/dev/null 2>&1; then
        nvm install --lts --reinstall-packages-from=current
        nvm alias default lts/*
    fi

    # 更新 lazy.nvim 插件
    echo "--- 更新 Neovim 插件 ---"
    if command -v nvim >/dev/null 2>&1; then
        nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
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
else
    echo ""
    echo "Editor 環境未安裝，略過更新"
fi

echo ""
echo "=== 更新完成 ==="
