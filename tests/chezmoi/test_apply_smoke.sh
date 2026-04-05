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

cat > "$tmp_root/chezmoi.toml" <<'EOF'
[data]
feature_editor = false
install_fonts = false
private_ssh_overlay = false
platform_profile = "auto"
EOF

run_apply() {
  "$CHEZMOI_BIN" \
    --config "$tmp_root/chezmoi.toml" \
    --cache "$cache_dir" \
    --persistent-state "$state_path" \
    -S "$ROOT_DIR" \
    -D "$dest_home" \
    apply --force --exclude=scripts
}

run_apply
run_apply

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "missing file: $path"
    exit 1
  fi
}

require_contains() {
  local path="$1"
  local pattern="$2"
  local message="$3"
  if ! rg -Fq "$pattern" "$path"; then
    echo "$message"
    exit 1
  fi
}

require_file "$dest_home/.zshrc"
require_file "$dest_home/.config/settingzsh/init.zsh"
require_file "$dest_home/.config/settingzsh/managed.d/10-base.zsh"
require_file "$dest_home/.config/settingzsh/managed.d/40-editor.zsh"
require_file "$dest_home/.ssh/config"
require_file "$dest_home/.ssh/config.d/10-common.conf"
require_file "$dest_home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
require_file "$dest_home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"

require_contains "$dest_home/.zshrc" ".config/settingzsh/init.zsh" ".zshrc missing bootstrap source"
require_contains "$dest_home/.ssh/config" "Include ~/.ssh/config.d/*.conf" ".ssh/config missing include model"

for unexpected in README.md docs tests home setup.sh update.sh Windows-Powershell; do
  if [ -e "$dest_home/$unexpected" ]; then
    echo "unexpected source repo payload in target home: $unexpected"
    exit 1
  fi
done

echo "chezmoi apply smoke: ok"
