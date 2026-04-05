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

require_file ".chezmoiroot"
require_file "home/.chezmoi.toml.tmpl"
require_file "home/.chezmoiexternal.toml.tmpl"
require_file "home/.chezmoidata/defaults.yaml"
require_file "home/.chezmoidata/artifacts.yaml"
require_file "home/.chezmoidata/linux.yaml"
require_file "home/.chezmoidata/macos.yaml"
require_file "home/.chezmoidata/windows.yaml"
require_file "home/modify_dot_zshrc"
require_file "home/private_dot_ssh/config.tmpl"
require_file "home/private_dot_ssh/config.d/10-common.conf.tmpl"
require_file "home/dot_config/settingzsh/powershell/public-baseline.ps1.tmpl"
require_file "home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl"
require_file "home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1.tmpl"

if ! grep -Fxq "home" .chezmoiroot; then
    echo ".chezmoiroot missing home source-root marker"
    exit 1
fi

require_contains "home/.chezmoi.toml.tmpl" "[data.features]" "chezmoi baseline config missing features section"
require_contains "home/.chezmoi.toml.tmpl" "[data.overlay]" "chezmoi baseline config missing overlay section"
require_contains "home/.chezmoi.toml.tmpl" "editor = false" "chezmoi baseline config missing editor default"
require_contains "home/.chezmoi.toml.tmpl" "fonts = true" "chezmoi baseline config missing fonts default"
require_contains "home/.chezmoi.toml.tmpl" 'private_ssh_overlay = false' "chezmoi baseline config missing private ssh overlay default"
require_contains "home/.chezmoi.toml.tmpl" 'repo = ""' "chezmoi baseline config missing overlay repo default"
require_contains "home/.chezmoi.toml.tmpl" 'profile = "auto"' "chezmoi baseline config missing overlay profile default"
if rg -q "feature_editor|install_fonts|private_ssh_overlay_repo" home/.chezmoi.toml.tmpl; then
    echo "chezmoi baseline config still contains legacy top-level keys"
    exit 1
fi
require_contains "home/.chezmoidata/defaults.yaml" "features:" "defaults schema missing features block"
require_contains "home/.chezmoidata/defaults.yaml" "editor: false" "defaults schema missing editor default"
require_contains "home/.chezmoidata/defaults.yaml" "fonts: true" "defaults schema missing fonts default"
require_contains "home/.chezmoidata/defaults.yaml" "private_ssh_overlay: false" "defaults schema missing private ssh overlay default"
require_contains "home/.chezmoidata/defaults.yaml" "overlay:" "defaults schema missing overlay block"
require_contains "home/.chezmoidata/defaults.yaml" 'repo: ""' "defaults schema missing overlay repo default"
require_contains "home/.chezmoidata/defaults.yaml" 'profile: "auto"' "defaults schema missing overlay profile default"
require_contains "home/.chezmoidata/artifacts.yaml" "ripgrep:" "artifacts schema missing ripgrep"
require_contains "home/.chezmoidata/artifacts.yaml" "fd:" "artifacts schema missing fd"
require_contains "home/.chezmoidata/artifacts.yaml" "neovim:" "artifacts schema missing neovim"
require_contains "home/.chezmoidata/artifacts.yaml" "lazygit:" "artifacts schema missing lazygit"
require_contains "home/.chezmoidata/artifacts.yaml" "linux:" "artifacts schema missing linux map"
require_contains "home/.chezmoidata/artifacts.yaml" "x86_64:" "artifacts schema missing x86_64 artifact"
require_contains "home/.chezmoidata/artifacts.yaml" "arm64:" "artifacts schema missing arm64 artifact"
require_contains "home/.chezmoiexternal.toml.tmpl" "private-ssh-overlay" "chezmoiexternal template missing overlay target"
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
