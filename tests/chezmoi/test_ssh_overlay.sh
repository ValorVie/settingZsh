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

private_repo="$tmp_root/private-repo"
dest_home="$tmp_root/home"
cache_dir="$tmp_root/cache"
state_path="$tmp_root/state.boltdb"
mkdir -p "$private_repo" "$dest_home" "$cache_dir"

mkdir -p \
  "$private_repo/shared/config.d" \
  "$private_repo/shared-keys/keys" \
  "$private_repo/testhost/config.d" \
  "$private_repo/testhost/keys" \
  "$private_repo/testhost/custom-paths/vendor"

cat > "$private_repo/shared/config.d/10-common-private.conf" <<'EOF'
Host github-work
  HostName github.com
  User git
EOF

cat > "$private_repo/shared-keys/keys/id_shared" <<'EOF'
shared-private-key
EOF

cat > "$private_repo/shared-keys/keys/README.md" <<'EOF'
do not deploy this readme
EOF

cat > "$private_repo/testhost/config.d/90-private.conf" <<'EOF'
Host app-prod
  HostName 10.0.0.9
  User ubuntu
  IdentityFile ~/.ssh/id_overlay
  IdentitiesOnly yes
EOF

cat > "$private_repo/testhost/keys/id_overlay" <<'EOF'
ENC:overlay-private-key
EOF

cat > "$private_repo/testhost/custom-paths/vendor/google_compute_engine" <<'EOF'
ENC:custom-private-key
EOF

git -C "$private_repo" init -q
git -C "$private_repo" config user.name "Codex"
git -C "$private_repo" config user.email "codex@example.com"
git -C "$private_repo" add .
git -C "$private_repo" commit -qm "test overlay repo"

cat > "$tmp_root/sops" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" != "decrypt" ] || [ -z "${2:-}" ]; then
  exit 1
fi

content="$(cat "$2")"
case "$content" in
  ENC:*)
    printf '%s' "${content#ENC:}"
    ;;
  *)
    exit 1
    ;;
esac
EOF
chmod +x "$tmp_root/sops"

write_config() {
  local config_path="$1"
  local overlay_enabled="$2"

  cat > "$config_path" <<EOF
[data]
feature_editor = false
install_fonts = false
private_ssh_overlay = $overlay_enabled
private_ssh_overlay_repo = "$(printf '%s' "$private_repo" | sed 's/\\/\\\\/g')"
platform_profile = "testhost"
EOF
}

run_overlay_script() {
  local config_path="$1"
  local output_path="$2"
  local rendered_script="$tmp_root/rendered-overlay.sh"

  "$CHEZMOI_BIN" \
    --config "$config_path" \
    --cache "$cache_dir" \
    -S "$ROOT_DIR" \
    -D "$dest_home" \
    execute-template --file home/run_onchange_after_40-install-private-ssh.sh.tmpl > "$rendered_script"
  chmod +x "$rendered_script"

  PATH="$tmp_root:$PATH" \
  HOME="$dest_home" \
  TMPDIR="$tmp_root" \
  "$rendered_script" > "$output_path" 2>&1
}

write_config "$tmp_root/overlay-disabled.toml" "false"
"$CHEZMOI_BIN" \
  --config "$tmp_root/overlay-disabled.toml" \
  --cache "$cache_dir" \
  -S "$ROOT_DIR" \
  -D "$dest_home" \
  execute-template --file home/.chezmoiexternal.toml.tmpl > "$tmp_root/overlay-disabled.toml.rendered"

if rg -Fq 'type = "git-repo"' "$tmp_root/overlay-disabled.toml.rendered"; then
  echo "disabled overlay still rendered git external"
  exit 1
fi

run_overlay_script "$tmp_root/overlay-disabled.toml" "$tmp_root/overlay-disabled.log"
if ! rg -Fq "private ssh overlay disabled" "$tmp_root/overlay-disabled.log"; then
  echo "disabled overlay script did not report disabled state"
  exit 1
fi

write_config "$tmp_root/overlay-enabled.toml" "true"
"$CHEZMOI_BIN" \
  --config "$tmp_root/overlay-enabled.toml" \
  --cache "$cache_dir" \
  --persistent-state "$state_path" \
  -S "$ROOT_DIR" \
  -D "$dest_home" \
  apply --force --exclude=scripts --refresh-externals=always

overlay_checkout="$dest_home/.local/share/settingzsh/private-ssh-overlay"
if [ ! -d "$overlay_checkout/.git" ]; then
  echo "overlay repo was not cloned by chezmoi external"
  exit 1
fi

run_overlay_script "$tmp_root/overlay-enabled.toml" "$tmp_root/overlay-enabled.log"
run_overlay_script "$tmp_root/overlay-enabled.toml" "$tmp_root/overlay-enabled-second.log"

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "missing file: $path"
    exit 1
  fi
}

require_mode() {
  local path="$1"
  local expected="$2"
  local actual
  actual="$(stat -c '%a' "$path")"
  if [ "$actual" != "$expected" ]; then
    echo "unexpected mode for $path"
    echo "expected: $expected"
    echo "actual:   $actual"
    exit 1
  fi
}

require_file "$dest_home/.ssh/config"
require_file "$dest_home/.ssh/config.d/10-common-private.conf"
require_file "$dest_home/.ssh/config.d/90-private.conf"
require_file "$dest_home/.ssh/id_shared"
require_file "$dest_home/.ssh/id_overlay"
require_file "$dest_home/.ssh/custom-paths/vendor/google_compute_engine"

if [ "$(cat "$dest_home/.ssh/id_overlay")" != "overlay-private-key" ]; then
  echo "overlay key was not decrypted and deployed correctly"
  exit 1
fi
if [ "$(cat "$dest_home/.ssh/custom-paths/vendor/google_compute_engine")" != "custom-private-key" ]; then
  echo "custom path key was not decrypted and deployed correctly"
  exit 1
fi
if [ "$(cat "$dest_home/.ssh/id_shared")" != "shared-private-key" ]; then
  echo "shared key was not copied correctly"
  exit 1
fi
if [ -e "$dest_home/.ssh/README.md" ]; then
  echo "overlay deployment copied README into ~/.ssh"
  exit 1
fi

require_mode "$dest_home/.ssh/config.d/10-common-private.conf" "600"
require_mode "$dest_home/.ssh/config.d/90-private.conf" "600"
require_mode "$dest_home/.ssh/id_shared" "600"
require_mode "$dest_home/.ssh/id_overlay" "600"
require_mode "$dest_home/.ssh/custom-paths/vendor/google_compute_engine" "600"

echo "private ssh overlay behavior: ok"
