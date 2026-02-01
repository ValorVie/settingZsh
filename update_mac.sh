#!/usr/bin/env bash
# macOS 環境更新已安裝的工具與套件
set -e

# 1. 更新 Homebrew 套件
echo "=== 更新 Homebrew 套件 ==="
brew update
brew upgrade

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
  ZINIT_HOME="${ZINIT_HOME:-${HOME}/.local/share/zinit/zinit.git}"
  zsh -i -c "source ${ZINIT_HOME}/zinit.zsh && zinit self-update && zinit update --all"
else
  echo "Zsh 尚未安裝，略過 Zinit 更新"
fi

# 5. 更新 Maple Mono NL NF CN 字型
MAPLE_VERSION="v7.9"
MAPLE_ARCHIVE="MapleMonoNL-NF-CN.zip"
echo "=== 下載最新 Maple Mono NL NF CN ==="
curl -OL "https://github.com/subframe7536/maple-font/releases/download/${MAPLE_VERSION}/${MAPLE_ARCHIVE}"
mkdir -p MapleMono
rm -rf MapleMono/*
unzip -o "${MAPLE_ARCHIVE}" -d MapleMono
mkdir -p ~/Library/Fonts
cp MapleMono/*.ttf ~/Library/Fonts/ 2>/dev/null || cp MapleMono/*.otf ~/Library/Fonts/ 2>/dev/null || true
rm -rf MapleMono
rm -f "${MAPLE_ARCHIVE}"

echo "=== 更新完成 ==="
