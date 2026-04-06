#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

tmp_root="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

home="$tmp_root/home"
backup_root="$tmp_root/backups"
mkdir -p "$home/.local/share/chezmoi" "$home/.config/settingzsh" "$home/.local/bin" "$backup_root"
mkdir -p "$home/Documents/PowerShell" "$home/Documents/WindowsPowerShell" "$home/.ssh/config.d"

cat > "$home/.zshrc" <<'EOF'
export TEST_VAR=1
# >>> settingZsh bootstrap >>>
[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"
# <<< settingZsh bootstrap <<<
EOF

cp "$ROOT_DIR/home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl" \
  "$home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
cp "$ROOT_DIR/home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1.tmpl" \
  "$home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"
cp "$ROOT_DIR/home/private_dot_ssh/config.tmpl" "$home/.ssh/config"
cp "$ROOT_DIR/home/private_dot_ssh/config.d/10-common.conf.tmpl" \
  "$home/.ssh/config.d/10-common.conf"

dry_run_output="$("$ROOT_DIR/scripts/uninstall-settingzsh.sh" --home "$home" --backup-root "$backup_root" --dry-run)"
printf '%s\n' "$dry_run_output" | rg -F ".local/share/chezmoi"
printf '%s\n' "$dry_run_output" | rg -F ".zshrc"
printf '%s\n' "$dry_run_output" | rg -F "PowerShell"
[ -d "$home/.local/share/chezmoi" ]
[ -f "$home/.zshrc" ]

execute_output="$("$ROOT_DIR/scripts/uninstall-settingzsh.sh" --home "$home" --backup-root "$backup_root" --execute)"
printf '%s\n' "$execute_output" | rg -F "backup_id:"
printf '%s\n' "$execute_output" | rg -F -- "--home $home"
printf '%s\n' "$execute_output" | rg -F -- "--backup-root $backup_root"
backup_id="$(printf '%s\n' "$execute_output" | rg -o 'backup_id: [^[:space:]]+' | awk '{print $2}' | tail -n 1)"
[ -n "$backup_id" ]
[ ! -d "$home/.local/share/chezmoi" ]
printf '%s\n' "$(cat "$home/.zshrc")" | rg -F "export TEST_VAR=1"
if rg -Fq "settingZsh bootstrap" "$home/.zshrc"; then
  echo "bootstrap block should be removed"
  exit 1
fi
[ -d "$home/.local/bin" ]
[ ! -f "$home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1" ]
[ ! -f "$home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1" ]
[ ! -f "$home/.ssh/config" ]
[ ! -f "$home/.ssh/config.d/10-common.conf" ]

manifest_dir="$backup_root/$backup_id"
[ -f "$manifest_dir/manifest.json" ]
[ -f "$manifest_dir/report.md" ]
printf '%s\n' "$(cat "$manifest_dir/report.md")" | rg -F -- "--home $home"
printf '%s\n' "$(cat "$manifest_dir/report.md")" | rg -F -- "--backup-root $backup_root"

"$ROOT_DIR/scripts/uninstall-settingzsh.sh" --home "$home" --backup-root "$backup_root" --restore "$backup_id"
[ -d "$home/.local/share/chezmoi" ]
printf '%s\n' "$(cat "$home/.zshrc")" | rg -F "settingZsh bootstrap"
printf '%s\n' "$(cat "$home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1")" | rg -F "public-baseline.ps1"
printf '%s\n' "$(cat "$home/.ssh/config")" | rg -F "Include ~/.ssh/config.d/*.conf"
printf '%s\n' "$(cat "$home/.ssh/config.d/10-common.conf")" | rg -F "shared safe SSH baseline"

echo "uninstall flow: ok"
