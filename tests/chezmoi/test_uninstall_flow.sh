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

cat > "$home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1" <<'EOF'
# managed by chezmoi: PowerShell 7+ profile target
$baselinePath = Join-Path $HOME ".config/settingzsh/powershell/public-baseline.ps1"
if (Test-Path $baselinePath) {
    . $baselinePath
}
EOF

cat > "$home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1" <<'EOF'
# managed by chezmoi: Windows PowerShell 5.1 profile target
$baselinePath = Join-Path $HOME ".config/settingzsh/powershell/public-baseline.ps1"
if (Test-Path $baselinePath) {
    . $baselinePath
}
EOF

cat > "$home/.ssh/config" <<'EOF'
# managed by chezmoi: settingZsh public baseline
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 3
  AddKeysToAgent yes

Include ~/.ssh/config.d/*.conf
EOF

cat > "$home/.ssh/config.d/10-common.conf" <<'EOF'
# managed by chezmoi: shared safe SSH baseline
#
# Add portable defaults that are safe across machines.
# Keep vendor-specific or private host entries in private overlay files,
# e.g. ~/.ssh/config.d/90-private.conf.
EOF

dry_run_output="$("$ROOT_DIR/scripts/uninstall-settingzsh.sh" --home "$home" --backup-root "$backup_root" --dry-run)"
printf '%s\n' "$dry_run_output" | rg -F ".local/share/chezmoi"
printf '%s\n' "$dry_run_output" | rg -F ".zshrc"
printf '%s\n' "$dry_run_output" | rg -F "PowerShell"
[ -d "$home/.local/share/chezmoi" ]
[ -f "$home/.zshrc" ]

execute_output="$("$ROOT_DIR/scripts/uninstall-settingzsh.sh" --home "$home" --backup-root "$backup_root" --execute)"
printf '%s\n' "$execute_output" | rg -F "backup_id:"
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
