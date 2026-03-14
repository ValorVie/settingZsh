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

require_file "README.md"
require_file "examples/valor-ssh-key/README.md"
require_file "examples/valor-ssh-key/.ssh/config.d/90-private.conf"
require_file "examples/valor-ssh-key/.ssh/id_ed25519.example"
require_file "examples/valor-ssh-key/.ssh/id_ed25519.pub.example"

require_contains "README.md" "custom private repo" "README missing custom private repo guide"
require_contains "README.md" "examples/valor-ssh-key" "README missing private repo template reference"
require_contains "examples/valor-ssh-key/README.md" '只管理 `.ssh/**`' "private repo template README missing scope guidance"
require_contains "examples/valor-ssh-key/.ssh/config.d/90-private.conf" "IdentityFile ~/.ssh/id_ed25519_work" "private repo sample missing identity example"

echo "private repo template checks: ok"
