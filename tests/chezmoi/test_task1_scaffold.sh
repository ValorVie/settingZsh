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

require_file "docs/plans/2026-03-15-settingzsh-capability-parity.md"
require_file ".chezmoi.toml.tmpl"
require_file ".chezmoidata/common.yaml"
require_file ".chezmoidata/macos.yaml"
require_file ".chezmoidata/linux.yaml"
require_file ".chezmoidata/windows.yaml"

if ! rg -qi "chezmoi" README.md; then
    echo "README missing chezmoi entry"
    exit 1
fi

if ! rg -q "feature_editor|private_ssh_overlay" .chezmoi.toml.tmpl; then
    echo ".chezmoi.toml.tmpl missing required feature keys"
    exit 1
fi

if ! rg -q "Linux 無 sudo fallback" docs/plans/2026-03-15-settingzsh-capability-parity.md; then
    echo "parity matrix missing Linux fallback row"
    exit 1
fi

if ! rg -q "Windows PowerShell modules" docs/plans/2026-03-15-settingzsh-capability-parity.md; then
    echo "parity matrix missing Windows modules row"
    exit 1
fi

echo "task1 scaffold checks: ok"
