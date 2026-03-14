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

require_file "run_once_before_10-install-base-packages.sh.tmpl"
require_file "run_once_before_20-install-fonts.sh.tmpl"
require_file "run_onchange_after_30-install-editor.sh.tmpl"
require_file "run_once_before_10-install-base-packages.ps1.tmpl"
require_file "run_once_before_20-install-fonts.ps1.tmpl"
require_file "run_onchange_after_30-install-editor.ps1.tmpl"

require_contains "run_once_before_10-install-base-packages.sh.tmpl" "{{ .chezmoi.os }}" "unix base script missing chezmoi os routing"
require_contains "run_once_before_10-install-base-packages.sh.tmpl" "astral.sh/uv/install.sh" "unix base script missing uv install path"
require_contains "run_once_before_20-install-fonts.sh.tmpl" "MapleMono" "unix fonts script missing Maple handling"
require_contains "run_onchange_after_30-install-editor.sh.tmpl" "SETTINGZSH_FEATURE_EDITOR" "unix editor script missing feature guard"
require_contains "run_onchange_after_30-install-editor.sh.tmpl" "nvim" "unix editor script missing nvim deployment path"
require_contains "run_onchange_after_30-install-editor.sh.tmpl" "config_merge.py" "unix editor script missing vimrc merge path"
require_contains "run_onchange_after_30-install-editor.sh.tmpl" '"$HOME/.vimrc"' "unix editor script missing vimrc target"

require_contains "run_once_before_10-install-base-packages.ps1.tmpl" "Terminal-Icons" "windows base script missing module setup"
require_contains "run_once_before_10-install-base-packages.ps1.tmpl" "winget" "windows base script missing winget usage"
require_contains "run_once_before_10-install-base-packages.ps1.tmpl" '$env:OS -eq "Windows_NT"' "windows base script missing PowerShell 5.1 compatible OS guard"
require_contains "run_once_before_20-install-fonts.ps1.tmpl" "MapleMonoNL-NF-CN.zip" "windows fonts script missing Maple download target"
require_contains "run_once_before_20-install-fonts.ps1.tmpl" '$env:OS -eq "Windows_NT"' "windows fonts script missing PowerShell 5.1 compatible OS guard"
require_contains "run_onchange_after_30-install-editor.ps1.tmpl" "SETTINGZSH_FEATURE_EDITOR" "windows editor script missing feature guard"
require_contains "run_onchange_after_30-install-editor.ps1.tmpl" "nvm" "windows editor script missing nvm/node setup"
require_contains "run_onchange_after_30-install-editor.ps1.tmpl" '$env:OS -eq "Windows_NT"' "windows editor script missing PowerShell 5.1 compatible OS guard"

echo "task4 scripts presence checks: ok"
