# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("$HOME/.zsh/completions" $fpath)
autoload -Uz compinit
compinit
# OPENSPEC:END

# === settingZsh:managed:zsh-base:begin ===
export PATH="$PATH:$HOME/.local/bin"
alias ls='ls --color'
# === settingZsh:managed:zsh-base:end ===

# === settingZsh:managed:editor:begin ===
lazy_nvm() {
  export NVM_DIR="$HOME/.nvm"
}
nvm() { lazy_nvm; command nvm "$@"; }
# === settingZsh:managed:editor:end ===

# === settingZsh:user:begin ===
export LC_CTYPE=en_US.UTF-8
# === settingZsh:user:end ===

# Added by Spectra
_spectra_path_prepend() { path=("$HOME/.local/bin" ${path:#$HOME/.local/bin}) }
precmd_functions+=(_spectra_path_prepend)
