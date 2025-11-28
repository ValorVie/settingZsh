#!/usr/bin/env bash
#
# 此腳本將在 Ubuntu/Debian 環境上安裝並設定 zsh + zinit + fzf + python313 + nerd fonts 等環境
# 使用方式：在終端機執行
#   chmod +x setup_env.sh
#   ./setup_env.sh
#
# 注意：chsh 預設會更改目前執行此腳本的使用者的 shell，如果需要更改其他使用者可再調整參數。

set -e  # 若某一指令失敗，則整個腳本退出
# 3. 備份並建立新的 ~/.zshrc
echo "=== 備份並建立新的 ~/.zshrc... ==="
if [ -f ~/.zshrc ]; then
  mv ~/.zshrc ~/.zshrc.bak
fi
touch ~/.zshrc

# 4. 安裝 Python 3.13 和 pip
echo "=== 安裝 python3.13 與 pip... ==="
sudo apt update -y
sudo apt install -y python3.13 python3-pip

# 5. 下載並安裝 JetBrainsMono Nerd Font
echo "=== 安裝 JetBrainsMono Nerd Font... ==="
curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
mkdir -p JetBrainsMono
tar -xf JetBrainsMono.tar.xz -C JetBrainsMono
mkdir -p ~/.local/share/fonts
mv JetBrainsMono/JetBrainsMonoNerdFont-* ~/.local/share/fonts/
fc-cache -fv

# 6. 建立補完檔案的快取資料夾
mkdir -p ~/.cache/zinit/completions

# 7. 安裝 fzf
echo "=== 安裝 fzf... ==="
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all --key-bindings --completion --no-bash --no-fish  # 自動安裝，避免互動式詢問

# 8. 安裝 zoxide
echo "=== 安裝 zoxide... ==="
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# 9. 將設定直接寫進 ~/.zshrc（取代原本的 nano 手動編輯）
echo "=== 寫入 zshrc 設定... ==="
cat << 'EOF' >> ~/.zshrc
# -----------------------------
# Zsh 配置開始
# -----------------------------

if [ "$(whoami)" = "root" ]; then
    export PATH="$PATH:/root/.local/bin"
else
    export PATH="$PATH:/home/$(whoami)/.local/bin"
fi

# Add env PATH
# export PATH="$PATH:/root/.local/bin"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macO you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins stage 1
zinit light zsh-users/zsh-completions

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::ansible
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found
zinit snippet OMZP::docker-compose
zinit snippet OMZP::docker
zinit snippet OMZ::lib/key-bindings.zsh

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Add in zsh plugins stage 2
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light djui/alias-tips

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings use `cat -v` check
# bindkey -e
bindkey '^f' autosuggest-accept
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey '^[[A' history-substring-search-up  
bindkey '^[[B' history-substring-search-down

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
# alias vim='nvim'
# alias c='clear'

# Add env PATH
export PATH="$PATH:/root/.local/bin"

# Shell integrations
eval "$(zoxide init --cmd cd zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Shell working directory reporting
precmd () { echo -n "\x1b]1337;CurrentDir=$(pwd)\x07" }

# -----------------------------
# Zsh 配置結束
# -----------------------------
EOF

# 10. 結束訊息
echo "=== 設定完成！若要使 Zsh 成為預設 shell，請重新登入或重新開啟終端機。 ==="
echo "=== 若要立即套用新設定，可直接執行：exec zsh ==="