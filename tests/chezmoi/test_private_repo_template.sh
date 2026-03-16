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
require_file "examples/valor-ssh-key/.sops.yaml.example"
require_file "examples/valor-ssh-key/shared/config.d/10-common-private.conf"
require_file "examples/valor-ssh-key/shared-keys/keys/README.md"
require_file "examples/valor-ssh-key/macmini/config.d/90-private.conf"
require_file "examples/valor-ssh-key/macmini/keys/.keep"
require_file "examples/valor-ssh-key/macmini/custom-paths/sympasoft-macmini-ssh/.keep"
require_file "examples/valor-ssh-key/valorpc/config.d/90-private.conf"
require_file "examples/valor-ssh-key/valorpc/keys/.keep"
require_file "examples/valor-ssh-key/valorpc/custom-paths/windows-imported/.keep"

require_contains "README.md" "custom private repo" "README missing custom private repo guide"
require_contains "README.md" "examples/valor-ssh-key" "README missing private repo template reference"
require_contains "README.md" "SOPS + age" "README missing SOPS + age reference"
require_contains "examples/valor-ssh-key/README.md" "shared-keys" "private repo template README missing shared-keys guidance"
require_contains "examples/valor-ssh-key/README.md" "custom-paths" "private repo template README missing custom-paths guidance"
require_contains "examples/valor-ssh-key/.sops.yaml.example" "creation_rules" "private repo sample missing sops creation rules"
require_contains "examples/valor-ssh-key/macmini/config.d/90-private.conf" "IgnoreUnknown UseKeychain" "macmini sample missing cross-platform keychain guard"
require_contains "examples/valor-ssh-key/valorpc/config.d/90-private.conf" "IdentitiesOnly yes" "valorpc sample missing explicit identity policy"

echo "private repo template checks: ok"
