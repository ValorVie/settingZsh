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

require_file "docs/plans/2026-03-15-settingzsh-capability-parity.md"
require_file ".chezmoiroot"
require_file "home/.chezmoi.toml.tmpl"
require_file "home/.chezmoidata/defaults.yaml"
require_file "home/.chezmoidata/artifacts.yaml"
require_file "home/.chezmoidata/macos.yaml"
require_file "home/.chezmoidata/linux.yaml"
require_file "home/.chezmoidata/windows.yaml"

if ! grep -Fxq "home" .chezmoiroot; then
    echo ".chezmoiroot missing home source-root marker"
    exit 1
fi

if ! rg -qi "chezmoi" README.md; then
    echo "README missing chezmoi entry"
    exit 1
fi

if ! rg -Fq "[data.features]" home/.chezmoi.toml.tmpl; then
    echo "home/.chezmoi.toml.tmpl missing [data.features] section"
    exit 1
fi
if ! rg -Fq "[data.overlay]" home/.chezmoi.toml.tmpl; then
    echo "home/.chezmoi.toml.tmpl missing [data.overlay] section"
    exit 1
fi
if ! rg -Fq 'editor = false' home/.chezmoi.toml.tmpl; then
    echo "home/.chezmoi.toml.tmpl missing editor default"
    exit 1
fi
if ! rg -Fq 'fonts = true' home/.chezmoi.toml.tmpl; then
    echo "home/.chezmoi.toml.tmpl missing fonts default"
    exit 1
fi
if ! rg -Fq 'private_ssh_overlay = false' home/.chezmoi.toml.tmpl; then
    echo "home/.chezmoi.toml.tmpl missing private ssh overlay default"
    exit 1
fi
if ! rg -Fq 'repo = ""' home/.chezmoi.toml.tmpl; then
    echo "home/.chezmoi.toml.tmpl missing overlay repo default"
    exit 1
fi
if ! rg -Fq 'profile = "auto"' home/.chezmoi.toml.tmpl; then
    echo "home/.chezmoi.toml.tmpl missing overlay profile default"
    exit 1
fi
if rg -q "feature_editor|install_fonts|private_ssh_overlay_repo" home/.chezmoi.toml.tmpl; then
    echo "home/.chezmoi.toml.tmpl still contains legacy top-level keys"
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

if ! rg -q "Linux 無 sudo fallback" docs/plans/2026-03-15-settingzsh-capability-parity.md; then
    echo "parity matrix missing Linux fallback row"
    exit 1
fi

if ! rg -q "Windows PowerShell modules" docs/plans/2026-03-15-settingzsh-capability-parity.md; then
    echo "parity matrix missing Windows modules row"
    exit 1
fi

echo "task1 scaffold checks: ok"
