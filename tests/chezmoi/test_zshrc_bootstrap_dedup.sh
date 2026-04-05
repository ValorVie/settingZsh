#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

CHEZMOI_BIN="${CHEZMOI_BIN:-/tmp/settingzsh-chezmoi-e2e/bin/chezmoi}"
if [ ! -x "$CHEZMOI_BIN" ]; then
  echo "chezmoi binary not found: $CHEZMOI_BIN"
  exit 1
fi

tmp_root="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

dest_home="$tmp_root/home"
cache_dir="$tmp_root/cache"
state_path="$tmp_root/state.boltdb"
mkdir -p "$dest_home" "$cache_dir"

cat > "$dest_home/.zshrc" <<'EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
. "$HOME/.local/bin/env"

# >>> settingZsh bootstrap >>>
[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"
# <<< settingZsh bootstrap <<<

# >>> settingZsh bootstrap >>>
[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"
# <<< settingZsh bootstrap <<<

# >>> settingZsh bootstrap >>>
[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"
# <<< settingZsh bootstrap <<<

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

"$CHEZMOI_BIN" \
  --cache "$cache_dir" \
  --persistent-state "$state_path" \
  -S "$ROOT_DIR" \
  -D "$dest_home" \
  apply --force --exclude=scripts

count="$(rg -c '^# >>> settingZsh bootstrap >>>$' "$dest_home/.zshrc")"
if [ "$count" -ne 1 ]; then
  echo "expected exactly one bootstrap block after chezmoi apply"
  echo "actual count: $count"
  exit 1
fi

if ! rg -Fq '. "$HOME/.local/bin/env"' "$dest_home/.zshrc"; then
  echo "existing zshrc content was not preserved"
  exit 1
fi

echo "zshrc bootstrap dedup behavior: ok"
