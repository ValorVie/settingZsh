#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

CHEZMOI_BIN="${CHEZMOI_BIN:-/tmp/settingzsh-chezmoi-e2e/bin/chezmoi}"
if [ ! -x "$CHEZMOI_BIN" ]; then
  echo "chezmoi binary not found: $CHEZMOI_BIN"
  exit 1
fi

tmp_root="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

dest_home="$tmp_root/home"
cache_dir="$tmp_root/cache"
mkdir -p "$dest_home" "$cache_dir" "$tmp_root/tmp"

cat > "$tmp_root/false.toml" <<'EOF'
[data]
install_fonts = false
EOF

cat > "$tmp_root/true.toml" <<'EOF'
[data]
install_fonts = true
EOF

cat > "$tmp_root/curl" <<EOF
#!/usr/bin/env bash
echo curl-invoked >> "$tmp_root/curl.log"
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
    execute-template --file home/run_once_before_20-install-fonts.sh.tmpl > "$output_path"
  chmod +x "$output_path"
}

run_script_and_capture() {
  local script_path="$1"
  local output_file="$2"

  PATH="$tmp_root:$PATH" \
  HOME="$dest_home" \
  TMPDIR="$tmp_root/tmp" \
  "$script_path" > "$output_file" 2>&1
}

render_script "$tmp_root/false.toml" "$tmp_root/fonts-disabled.sh"
run_script_and_capture "$tmp_root/fonts-disabled.sh" "$tmp_root/fonts-disabled.log"

if ! rg -Fq "fonts feature disabled" "$tmp_root/fonts-disabled.log"; then
  echo "fonts script did not report disabled state from config"
  exit 1
fi
if [ -f "$tmp_root/curl.log" ]; then
  echo "fonts script invoked curl when install_fonts=false"
  exit 1
fi

render_script "$tmp_root/true.toml" "$tmp_root/fonts-env-disabled.sh"
SETTINGZSH_INSTALL_FONTS=false run_script_and_capture \
  "$tmp_root/fonts-env-disabled.sh" \
  "$tmp_root/fonts-env-disabled.log"

if ! rg -Fq "fonts feature disabled" "$tmp_root/fonts-env-disabled.log"; then
  echo "fonts script did not honor SETTINGZSH_INSTALL_FONTS override"
  exit 1
fi
if [ -f "$tmp_root/curl.log" ]; then
  echo "fonts script invoked curl when env override disabled fonts"
  exit 1
fi

echo "fonts feature gating behavior: ok"
