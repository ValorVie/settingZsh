#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

BASE_SCRIPT="run_once_before_10-install-base-packages.sh.tmpl"
EDITOR_SCRIPT="run_onchange_after_30-install-editor.sh.tmpl"

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

require_file "$BASE_SCRIPT"
require_file "$EDITOR_SCRIPT"

# Task 5 hard requirement: sudo checks must be non-interactive safe.
require_contains "$BASE_SCRIPT" "sudo -n true" "base script missing non-interactive sudo check"
require_contains "$EDITOR_SCRIPT" "sudo -n true" "editor script missing non-interactive sudo check"

# Task 5 hard requirement: no-sudo path must include binary fallback for editor stack.
require_contains "$EDITOR_SCRIPT" "BurntSushi/ripgrep" "editor script missing ripgrep binary fallback"
require_contains "$EDITOR_SCRIPT" "sharkdp/fd" "editor script missing fd binary fallback"
require_contains "$EDITOR_SCRIPT" "nvim-linux-x86_64.tar.gz" "editor script missing neovim binary fallback"
require_contains "$EDITOR_SCRIPT" "jesseduffield/lazygit" "editor script missing lazygit binary fallback"

echo "task5 linux fallback checks: ok"
