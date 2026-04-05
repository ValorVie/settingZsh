#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

BASE_SCRIPT="home/run_once_before_10-install-base-packages.sh.tmpl"
EDITOR_SCRIPT="home/run_onchange_after_30-install-editor.sh.tmpl"
CHEZMOI_BIN="${CHEZMOI_BIN:-/tmp/settingzsh-chezmoi-e2e/bin/chezmoi}"

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

tmp_root="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

dest_home="$tmp_root/home"
cache_dir="$tmp_root/cache"
mkdir -p "$dest_home" "$cache_dir" "$tmp_root/tmp"

cat > "$tmp_root/false.toml" <<'EOF'
[data.features]
editor = false
EOF

cat > "$tmp_root/true.toml" <<'EOF'
[data.features]
editor = true
EOF

cat > "$tmp_root/uname" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  -m)
    printf '%s\n' "${SETTINGZSH_TEST_UNAME_M:-x86_64}"
    ;;
  *)
    /usr/bin/uname "$@"
    ;;
esac
EOF
chmod +x "$tmp_root/uname"

cat > "$tmp_root/curl" <<'EOF'
#!/usr/bin/env bash
printf 'curl-invoked:%s\n' "$*" >> "${TMPDIR:-/tmp}/curl.log"
exit 99
EOF
chmod +x "$tmp_root/curl"

render_script() {
  local config_path="$1"
  local output_path="$2"

  "$CHEZMOI_BIN" \
    --config "$config_path" \
    --cache "$cache_dir" \
    -S "$ROOT_DIR" \
    -D "$dest_home" \
    execute-template --file home/run_onchange_after_30-install-editor.sh.tmpl > "$output_path"
  chmod +x "$output_path"
}

strip_runtime_tail() {
  local input_path="$1"
  local output_path="$2"

  awk '/^case "\$OS"/ { exit } { print }' "$input_path" > "$output_path"
}

harness_eval() {
  local arch="$1"
  local harness_path="$2"
  local code="$3"

  PATH="$tmp_root:$PATH" \
  HOME="$dest_home" \
  TMPDIR="$tmp_root/tmp" \
  SETTINGZSH_TEST_UNAME_M="$arch" \
    bash -c "set -euo pipefail; source \"$harness_path\"; $code"
}

# Template expressions must come from canonical artifacts, not hand-built version strings.
require_contains "$EDITOR_SCRIPT" 'index . "artifacts" "ripgrep" "linux" "x86_64"' "editor script missing canonical ripgrep x86_64 artifact URL"
require_contains "$EDITOR_SCRIPT" 'index . "artifacts" "ripgrep" "linux" "arm64"' "editor script missing canonical ripgrep arm64 artifact URL"
require_contains "$EDITOR_SCRIPT" 'index . "artifacts" "fd" "linux" "x86_64"' "editor script missing canonical fd x86_64 artifact URL"
require_contains "$EDITOR_SCRIPT" 'index . "artifacts" "fd" "linux" "arm64"' "editor script missing canonical fd arm64 artifact URL"
require_contains "$EDITOR_SCRIPT" 'index . "artifacts" "neovim" "linux" "x86_64"' "editor script missing canonical neovim x86_64 artifact URL"
require_contains "$EDITOR_SCRIPT" 'index . "artifacts" "neovim" "linux" "arm64"' "editor script missing canonical neovim arm64 artifact URL"
require_contains "$EDITOR_SCRIPT" 'index . "artifacts" "lazygit" "linux" "x86_64"' "editor script missing canonical lazygit x86_64 artifact URL"
require_contains "$EDITOR_SCRIPT" 'index . "artifacts" "lazygit" "linux" "arm64"' "editor script missing canonical lazygit arm64 artifact URL"
if rg -Fq 'RIPGREP_VERSION=' "$EDITOR_SCRIPT" || rg -Fq 'FD_VERSION=' "$EDITOR_SCRIPT" || rg -Fq 'LAZYGIT_VERSION=' "$EDITOR_SCRIPT"; then
  echo "editor script still hand-rolls package versions"
  exit 1
fi

# Task 5 hard requirement: sudo checks must be non-interactive safe.
require_contains "$BASE_SCRIPT" "sudo -n true" "base script missing non-interactive sudo check"
require_contains "$EDITOR_SCRIPT" "sudo -n true" "editor script missing non-interactive sudo check"
require_contains "$EDITOR_SCRIPT" "detect_arch()" "editor script missing detect_arch helper"
require_contains "$EDITOR_SCRIPT" "unsupported" "editor script missing unsupported arch path"

render_script "$tmp_root/false.toml" "$tmp_root/editor-false.sh"
render_script "$tmp_root/true.toml" "$tmp_root/editor-true.sh"
require_contains "$tmp_root/editor-false.sh" 'FEATURE_EDITOR_DEFAULT="false"' "editor render did not honor features.editor=false"
require_contains "$tmp_root/editor-true.sh" 'FEATURE_EDITOR_DEFAULT="true"' "editor render did not honor features.editor=true"

strip_runtime_tail "$tmp_root/editor-true.sh" "$tmp_root/editor-harness.sh"

x86_detect="$(harness_eval "x86_64" "$tmp_root/editor-harness.sh" 'detect_arch')"
if [ "$x86_detect" != "x86_64" ]; then
  echo "detect_arch did not normalize x86_64"
  exit 1
fi

x86_select="$(harness_eval "x86_64" "$tmp_root/editor-harness.sh" 'select_arch_value x86-url arm-url')"
if [ "$x86_select" != "x86-url" ]; then
  echo "select_arch_value did not choose x86_64 artifact"
  exit 1
fi

arm_detect="$(harness_eval "aarch64" "$tmp_root/editor-harness.sh" 'detect_arch')"
if [ "$arm_detect" != "arm64" ]; then
  echo "detect_arch did not normalize arm64"
  exit 1
fi

arm_select="$(harness_eval "arm64" "$tmp_root/editor-harness.sh" 'select_arch_value x86-url arm-url')"
if [ "$arm_select" != "arm-url" ]; then
  echo "select_arch_value did not choose arm64 artifact"
  exit 1
fi

unsupported_detect="$(harness_eval "riscv64" "$tmp_root/editor-harness.sh" 'detect_arch')"
if [ "$unsupported_detect" != "unsupported" ]; then
  echo "detect_arch did not report unsupported arch"
  exit 1
fi

if harness_eval "riscv64" "$tmp_root/editor-harness.sh" 'select_arch_value x86-url arm-url' >/dev/null 2>&1; then
  echo "select_arch_value silently fell back on unsupported arch"
  exit 1
fi

rm -f "$tmp_root/tmp/curl.log"
unsupported_log="$tmp_root/unsupported-nvim.log"
PATH="$tmp_root:$PATH" \
HOME="$dest_home" \
TMPDIR="$tmp_root/tmp" \
SETTINGZSH_TEST_UNAME_M="riscv64" \
  bash -c "set -euo pipefail; source \"$tmp_root/editor-harness.sh\"; install_nvim_fallback" > "$unsupported_log" 2>&1

if ! rg -Fq "unsupported architecture for neovim fallback" "$unsupported_log"; then
  echo "unsupported neovim fallback did not report unsupported architecture"
  exit 1
fi
if [ -f "$tmp_root/tmp/curl.log" ]; then
  echo "unsupported neovim fallback invoked curl"
  exit 1
fi

echo "task5 linux fallback behavior: ok"
