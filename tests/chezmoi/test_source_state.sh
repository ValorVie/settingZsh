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

require_file "home/modify_dot_zshrc"
require_file "home/private_dot_ssh/config.tmpl"
require_file "home/private_dot_ssh/config.d/10-common.conf.tmpl"
require_file "home/dot_config/settingzsh/powershell/public-baseline.ps1.tmpl"
require_file "home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl"
require_file "home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1.tmpl"

require_contains "home/modify_dot_zshrc" ".config/settingzsh/init.zsh" "zsh bootstrap missing init source"
require_contains "home/private_dot_ssh/config.tmpl" "Host *" "ssh main config missing Host *"
require_contains "home/private_dot_ssh/config.tmpl" "Include ~/.ssh/config.d/*.conf" "ssh main config missing Include model"
require_contains "home/dot_config/settingzsh/powershell/public-baseline.ps1.tmpl" "PSVersionTable.PSVersion.Major" "powershell baseline missing major-version branch"
require_contains "home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl" "public-baseline.ps1" "pwsh 7 profile missing baseline snippet source"
require_contains "home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1.tmpl" "public-baseline.ps1" "pwsh 5.1 profile missing baseline snippet source"

if [ -f "home/dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl" ]; then
    echo "misleading powershell target strategy still present"
    exit 1
fi

if [ -f "home/dot_zshrc.tmpl" ]; then
    echo "legacy whole-file zshrc source state still present"
    exit 1
fi
if ! grep -Fxq '# chezmoi:modify-template' home/modify_dot_zshrc; then
    echo "modify zshrc source state missing modify-template marker"
    exit 1
fi
if ! rg -Fq '.chezmoi.stdin' home/modify_dot_zshrc; then
    echo "modify zshrc source state missing stdin handling"
    exit 1
fi
if ! rg -Fq '# managed by chezmoi: settingZsh public baseline' home/modify_dot_zshrc; then
    echo "modify zshrc source state missing bootstrap create path"
    exit 1
fi
if ! rg -Fq '# >>> settingZsh bootstrap >>>' home/modify_dot_zshrc; then
    echo "modify zshrc source state missing bootstrap block insert path"
    exit 1
fi
if rg -q -e 'zinit|compinit|brew shellenv|zoxide init|bindkey|HISTSIZE|alias ' home/modify_dot_zshrc; then
    echo "modify zshrc source state includes baseline logic that should stay in later tasks"
    exit 1
fi

if rg -q -e 'IdentitiesOnly|IdentityFile' home/private_dot_ssh/config.tmpl; then
    echo "ssh main config includes identity-pin directives"
    exit 1
fi
if rg -q -e 'IdentitiesOnly|IdentityFile|ProxyJump|ProxyCommand|CertificateFile' home/private_dot_ssh/config.d/10-common.conf.tmpl; then
    echo "ssh common config includes private or environment-specific directives"
    exit 1
fi
if rg -q -i -e 'github|gitlab|bitbucket' home/private_dot_ssh/config.d/10-common.conf.tmpl; then
    echo "ssh common config includes vendor-specific hosts"
    exit 1
fi

if rg -q -e 'Install-Module|winget|Invoke-WebRequest|choco|Start-BitsTransfer|curl.exe' home/dot_config/settingzsh/powershell/public-baseline.ps1.tmpl; then
    echo "powershell baseline includes installer logic that belongs in run scripts"
    exit 1
fi
if rg -q -e '\$ErrorActionPreference\s*=\s*"Stop"' home/dot_config/settingzsh/powershell/public-baseline.ps1.tmpl; then
    echo "powershell baseline should not set global ErrorActionPreference to Stop"
    exit 1
fi

echo "task2 source state checks: ok"
