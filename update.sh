#!/usr/bin/env bash
# 更新已安裝的工具與套件
set -e

# 1. 更新系統套件
echo "=== 更新系統套件 ==="
sudo apt update -y
sudo apt upgrade -y

# 2. 更新 fzf
if [ -d "$HOME/.fzf" ]; then
  echo "=== 更新 fzf ==="
  git -C "$HOME/.fzf" pull
  "$HOME/.fzf/install" --all --key-bindings --completion --no-bash --no-fish
else
  echo "fzf 尚未安裝，略過更新"
fi

# 3. 更新 zoxide
echo "=== 更新 zoxide ==="
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# 4. 更新 zinit 以及所有插件
if command -v zsh >/dev/null 2>&1; then
  echo "=== 更新 Zinit 及其插件 ==="
  zsh -i -c "source \${ZINIT_HOME:-\${HOME}/.local/share}/zinit/zinit.git/zinit.zsh && zinit self-update && zinit update --all"
else
  echo "Zsh 尚未安裝，略過 Zinit 更新"
fi

# 5. 更新 JetBrainsMono Nerd Font
FONT_ARCHIVE="JetBrainsMono.tar.xz"
echo "=== 下載最新 JetBrainsMono Nerd Font ==="
curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_ARCHIVE}
mkdir -p JetBrainsMono
rm -rf JetBrainsMono/*
tar -xf ${FONT_ARCHIVE} -C JetBrainsMono
mkdir -p "$HOME/.local/share/fonts"
mv JetBrainsMono/JetBrainsMonoNerdFont-* "$HOME/.local/share/fonts/"
fc-cache -fv
rm -f ${FONT_ARCHIVE}

echo "=== 更新完成 ==="
