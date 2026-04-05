#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

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

require_file "home/run_once_before_10-install-base-packages.sh.tmpl"
require_file "home/run_once_before_15-install-zinit.sh.tmpl"
require_file "home/run_once_before_20-install-fonts.sh.tmpl"
require_file "home/run_onchange_after_30-install-editor.sh.tmpl"
require_file "home/run_onchange_after_40-install-private-ssh.sh.tmpl"
require_file "home/run_once_before_10-install-base-packages.ps1.tmpl"
require_file "home/run_once_before_20-install-fonts.ps1.tmpl"
require_file "home/run_onchange_after_30-install-editor.ps1.tmpl"
require_file "home/run_onchange_after_40-install-private-ssh.ps1.tmpl"

require_contains "home/run_once_before_10-install-base-packages.sh.tmpl" "{{ .chezmoi.os }}" "unix base script missing chezmoi os routing"
require_contains "home/run_once_before_10-install-base-packages.sh.tmpl" "astral.sh/uv/install.sh" "unix base script missing uv install path"
require_contains "home/run_once_before_15-install-zinit.sh.tmpl" "zdharma-continuum/zinit" "unix zinit script missing zinit bootstrap"
require_contains "home/run_once_before_15-install-zinit.sh.tmpl" "interactive zsh startup" "unix zinit script missing bootstrap hint"
require_contains "home/run_once_before_20-install-fonts.sh.tmpl" "MapleMono" "unix fonts script missing Maple handling"
require_contains "home/run_once_before_20-install-fonts.sh.tmpl" "SETTINGZSH_INSTALL_FONTS" "unix fonts script missing feature guard"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" "SETTINGZSH_FEATURE_EDITOR" "unix editor script missing feature guard"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" "nvim" "unix editor script missing nvim deployment path"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" "config_merge.py" "unix editor script missing vimrc merge path"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" '"$HOME/.vimrc"' "unix editor script missing vimrc target"
require_contains "home/run_onchange_after_40-install-private-ssh.sh.tmpl" "private ssh overlay" "unix private ssh script missing overlay status output"
require_contains "home/run_onchange_after_40-install-private-ssh.sh.tmpl" ".ssh/custom-paths" "unix private ssh script missing custom-paths target"
require_contains "home/run_onchange_after_40-install-private-ssh.sh.tmpl" "sops decrypt" "unix private ssh script missing sops decrypt support"

require_contains "home/run_once_before_10-install-base-packages.ps1.tmpl" "Terminal-Icons" "windows base script missing module setup"
require_contains "home/run_once_before_10-install-base-packages.ps1.tmpl" "winget" "windows base script missing winget usage"
require_contains "home/run_once_before_10-install-base-packages.ps1.tmpl" '$env:OS -eq "Windows_NT"' "windows base script missing PowerShell 5.1 compatible OS guard"
require_contains "home/run_once_before_20-install-fonts.ps1.tmpl" 'get (get . "features") "fonts"' "windows fonts script missing nested features.fonts lookup"
require_contains "home/run_once_before_20-install-fonts.ps1.tmpl" "MapleMonoNL-NF-CN.zip" "windows fonts script missing Maple download target"
require_contains "home/run_once_before_20-install-fonts.ps1.tmpl" "SETTINGZSH_INSTALL_FONTS" "windows fonts script missing feature guard"
require_contains "home/run_once_before_20-install-fonts.ps1.tmpl" '$env:OS -eq "Windows_NT"' "windows fonts script missing PowerShell 5.1 compatible OS guard"
require_contains "home/run_onchange_after_30-install-editor.ps1.tmpl" 'get (get . "features") "editor"' "windows editor script missing nested features.editor lookup"
require_contains "home/run_onchange_after_30-install-editor.ps1.tmpl" "SETTINGZSH_FEATURE_EDITOR" "windows editor script missing feature guard"
require_contains "home/run_onchange_after_30-install-editor.ps1.tmpl" "nvm" "windows editor script missing nvm/node setup"
require_contains "home/run_onchange_after_30-install-editor.ps1.tmpl" '$env:OS -eq "Windows_NT"' "windows editor script missing PowerShell 5.1 compatible OS guard"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" 'get (get . "features") "private_ssh_overlay"' "windows private ssh script missing nested features.private_ssh_overlay lookup"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" 'get (get . "overlay") "repo"' "windows private ssh script missing nested overlay.repo lookup"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" 'get (get . "overlay") "profile"' "windows private ssh script missing nested overlay.profile lookup"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" "SETTINGZSH_PRIVATE_SSH_OVERLAY" "windows private ssh script missing overlay feature guard"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" "custom-paths" "windows private ssh script missing custom-paths target"

echo "task4 scripts presence checks: ok"
