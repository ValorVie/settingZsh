
# -----------------------------
# Editor 環境配置
# -----------------------------

# nvm lazy loading（延遲載入，加速 shell 啟動）
lazy_nvm() {
    unset -f nvm node npm npx
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm()  { lazy_nvm; nvm "$@"; }
node() { lazy_nvm; node "$@"; }
npm()  { lazy_nvm; npm "$@"; }
npx()  { lazy_nvm; npx "$@"; }

# -----------------------------
# Editor 環境配置結束
# -----------------------------
