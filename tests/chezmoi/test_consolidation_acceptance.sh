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

require_absent() {
  local path="$1"
  if [ -e "$path" ]; then
    echo "unexpected path still present: $path"
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

require_not_contains() {
  local path="$1"
  local pattern="$2"
  local message="$3"
  if rg -Fq "$pattern" "$path"; then
    echo "$message"
    exit 1
  fi
}

require_absent "templates"
require_absent "lib/settingzsh/shellgen.py"

require_file "home/.chezmoi.toml.tmpl"
require_file "home/.chezmoidata/defaults.yaml"
require_file "home/.chezmoidata/artifacts.yaml"
require_file "lib/settingzsh/cli.py"

require_contains "home/.chezmoi.toml.tmpl" "[data.features]" "chezmoi template missing nested features schema"
require_contains "home/.chezmoi.toml.tmpl" "[data.overlay]" "chezmoi template missing nested overlay schema"
require_contains "home/.chezmoi.toml.tmpl" 'editor = false' "chezmoi template missing editor default"
require_contains "home/.chezmoi.toml.tmpl" 'fonts = true' "chezmoi template missing fonts default"
require_contains "home/.chezmoi.toml.tmpl" 'private_ssh_overlay = false' "chezmoi template missing private ssh overlay default"
require_contains "home/.chezmoi.toml.tmpl" 'repo = ""' "chezmoi template missing overlay repo default"
require_contains "home/.chezmoi.toml.tmpl" 'profile = "auto"' "chezmoi template missing overlay profile default"
require_not_contains "home/.chezmoi.toml.tmpl" "feature_editor" "chezmoi template still contains legacy feature_editor key"
require_not_contains "home/.chezmoi.toml.tmpl" "install_fonts" "chezmoi template still contains legacy install_fonts key"
require_not_contains "home/.chezmoi.toml.tmpl" "private_ssh_overlay_repo" "chezmoi template still contains legacy private_ssh_overlay_repo key"

require_contains "home/.chezmoidata/defaults.yaml" "features:" "defaults schema missing features block"
require_contains "home/.chezmoidata/defaults.yaml" "overlay:" "defaults schema missing overlay block"
require_contains "home/.chezmoidata/defaults.yaml" "editor: false" "defaults schema missing editor default"
require_contains "home/.chezmoidata/defaults.yaml" "fonts: true" "defaults schema missing fonts default"
require_contains "home/.chezmoidata/defaults.yaml" "private_ssh_overlay: false" "defaults schema missing private ssh overlay default"
require_contains "home/.chezmoidata/defaults.yaml" 'repo: ""' "defaults schema missing overlay repo default"
require_contains "home/.chezmoidata/defaults.yaml" 'profile: "auto"' "defaults schema missing overlay profile default"

require_contains "home/.chezmoidata/artifacts.yaml" "ripgrep:" "artifact map missing ripgrep"
require_contains "home/.chezmoidata/artifacts.yaml" "fd:" "artifact map missing fd"
require_contains "home/.chezmoidata/artifacts.yaml" "neovim:" "artifact map missing neovim"
require_contains "home/.chezmoidata/artifacts.yaml" "lazygit:" "artifact map missing lazygit"
require_contains "home/.chezmoidata/artifacts.yaml" "linux:" "artifact map missing linux nested map"
require_contains "home/.chezmoidata/artifacts.yaml" "x86_64:" "artifact map missing x86_64 entry"
require_contains "home/.chezmoidata/artifacts.yaml" "arm64:" "artifact map missing arm64 entry"

require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" 'index . "artifacts" "ripgrep" "linux" "x86_64"' "editor template missing canonical ripgrep x86_64 artifact"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" 'index . "artifacts" "fd" "linux" "arm64"' "editor template missing canonical fd arm64 artifact"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" 'index . "artifacts" "neovim" "linux" "x86_64"' "editor template missing canonical neovim x86_64 artifact"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" 'index . "artifacts" "lazygit" "linux" "arm64"' "editor template missing canonical lazygit arm64 artifact"

bash tests/chezmoi/test_linux_fallback.sh

python3 - <<'PY'
import io
import sys
import tempfile
from contextlib import redirect_stderr
from pathlib import Path

root = Path.cwd()
sys.path.insert(0, str(root / "lib"))

from settingzsh.cli import run_reconcile
from settingzsh.cli import run_setup
from settingzsh.cli import run_update
from settingzsh.migrate import run_migrate

cases = [
    (run_setup, "setup 已停用", "chezmoi init --apply"),
    (run_update, "update 已停用", "chezmoi update"),
    (run_migrate, "migrate 已停用", "legacy-import"),
    (run_reconcile, "reconcile 已停用", "chezmoi apply"),
]

with tempfile.TemporaryDirectory() as tmp:
    home = Path(tmp) / "home"
    home.mkdir(parents=True, exist_ok=True)
    before = "export TEST_VAR=1\n"
    zshrc = home / ".zshrc"
    zshrc.write_text(before, encoding="utf-8")

    for runner, retired_marker, guidance in cases:
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            result = runner(target_home=home)

        assert result.status == "deprecated", result.status
        assert result.modified_files == [], result.modified_files
        assert retired_marker in stderr.getvalue(), stderr.getvalue()
        assert guidance in stderr.getvalue(), stderr.getvalue()
        assert zshrc.read_text(encoding="utf-8") == before
        assert not (home / ".config" / "settingzsh").exists()

print("cli deprecated guidance: ok")
PY

echo "consolidation acceptance: ok"
