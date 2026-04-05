#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

require_first_line() {
  local path="$1"
  local expected="$2"
  local message="$3"
  local actual
  actual="$(head -n 1 "$path")"
  if [ "$actual" != "$expected" ]; then
    echo "$message"
    echo "expected: $expected"
    echo "actual:   $actual"
    exit 1
  fi
}

require_last_line() {
  local path="$1"
  local expected="$2"
  local message="$3"
  local actual
  actual="$(tail -n 1 "$path")"
  if [ "$actual" != "$expected" ]; then
    echo "$message"
    echo "expected: $expected"
    echo "actual:   $actual"
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

for script in \
  home/run_once_before_10-install-base-packages.ps1.tmpl \
  home/run_once_before_20-install-fonts.ps1.tmpl \
  home/run_onchange_after_30-install-editor.ps1.tmpl
do
  require_first_line "$script" '{{- if eq .chezmoi.os "windows" -}}' "$script missing windows-only template gate"
  require_last_line "$script" '{{- end -}}' "$script missing closing template gate"
done

for script in \
  home/run_once_before_10-install-base-packages.sh.tmpl \
  home/run_once_before_20-install-fonts.sh.tmpl \
  home/run_onchange_after_30-install-editor.sh.tmpl
do
  require_first_line "$script" '{{- if ne .chezmoi.os "windows" -}}' "$script missing non-windows template gate"
  require_last_line "$script" '{{- end -}}' "$script missing closing template gate"
done

require_contains ".chezmoiroot" 'home' ".chezmoiroot missing home source-root marker"
require_contains "home/.chezmoiignore.tmpl" '{{- if ne .chezmoi.os "windows" }}' "home/.chezmoiignore.tmpl missing non-windows ignore gate"
require_contains "home/.chezmoiignore.tmpl" '10-install-base-packages.ps1' "home/.chezmoiignore.tmpl missing powershell base script ignore"
require_contains "home/.chezmoiignore.tmpl" '20-install-fonts.ps1' "home/.chezmoiignore.tmpl missing powershell fonts script ignore"
require_contains "home/.chezmoiignore.tmpl" '30-install-editor.ps1' "home/.chezmoiignore.tmpl missing powershell editor script ignore"
require_contains "home/.chezmoiignore.tmpl" '{{- if eq .chezmoi.os "windows" }}' "home/.chezmoiignore.tmpl missing windows ignore gate"
require_contains "home/.chezmoiignore.tmpl" '10-install-base-packages.sh' "home/.chezmoiignore.tmpl missing shell base script ignore"
require_contains "home/.chezmoiignore.tmpl" '20-install-fonts.sh' "home/.chezmoiignore.tmpl missing shell fonts script ignore"
require_contains "home/.chezmoiignore.tmpl" '30-install-editor.sh' "home/.chezmoiignore.tmpl missing shell editor script ignore"

echo "platform script gating checks: ok"
