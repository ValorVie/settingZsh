# managed fragment template: settingZsh base (Linux compatibility source)

typeset -U path fpath
if [[ "$(id -u)" -eq 0 ]]; then
  path+=("/root/.local/bin")
else
  path+=("/home/$(whoami)/.local/bin")
fi
export PATH

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"

  zinit ice depth=1
  zinit light romkatv/powerlevel10k
  zinit light zsh-users/zsh-completions

  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZP::ansible
  zinit snippet OMZP::kubectl
  zinit snippet OMZP::kubectx
  zinit snippet OMZP::command-not-found
  zinit snippet OMZP::docker-compose
  zinit snippet OMZP::docker
  zinit snippet OMZ::lib/key-bindings.zsh

  autoload -Uz compinit && compinit
  zinit cdreplay -q

  zinit light Aloxaf/fzf-tab
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-autosuggestions
  zinit light zsh-users/zsh-history-substring-search
  zinit light djui/alias-tips
fi

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

bindkey '^f' autosuggest-accept
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

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

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

alias ls='ls --color'
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

_settingzsh_emit_currentdir() {
  echo -n "\x1b]1337;CurrentDir=$(pwd)\x07"
  printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"
}

if (( ${precmd_functions[(I)_settingzsh_emit_currentdir]} == 0 )); then
  precmd_functions+=(_settingzsh_emit_currentdir)
fi
