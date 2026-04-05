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

require_not_contains() {
  local path="$1"
  local pattern="$2"
  local message="$3"
  if rg -Fq "$pattern" "$path"; then
    echo "$message"
    exit 1
  fi
}

require_file "home/run_once_before_10-install-base-packages.sh.tmpl"
require_file "home/run_once_before_15-install-zinit.sh.tmpl"
require_file "home/run_once_before_20-install-fonts.sh.tmpl"
require_file "home/run_onchange_after_30-install-editor.sh.tmpl"
require_file "home/run_onchange_after_40-install-private-ssh.sh.tmpl"
require_file "home/run_once_before_10-install-base-packages.ps1.tmpl"
require_file "home/run_once_before_20-install-fonts.ps1.tmpl"
require_file "home/run_onchange_after_30-install-editor.ps1.tmpl"
require_file "home/run_onchange_after_40-install-private-ssh.ps1.tmpl"

require_contains "home/run_once_before_10-install-base-packages.sh.tmpl" "{{ .chezmoi.os }}" "unix base script missing chezmoi os routing"
require_contains "home/run_once_before_10-install-base-packages.sh.tmpl" "astral.sh/uv/install.sh" "unix base script missing uv install path"
require_contains "home/run_once_before_15-install-zinit.sh.tmpl" "zdharma-continuum/zinit" "unix zinit script missing zinit bootstrap"
require_contains "home/run_once_before_15-install-zinit.sh.tmpl" "interactive zsh startup" "unix zinit script missing bootstrap hint"
require_contains "home/run_once_before_20-install-fonts.sh.tmpl" "MapleMono" "unix fonts script missing Maple handling"
require_contains "home/run_once_before_20-install-fonts.sh.tmpl" "SETTINGZSH_INSTALL_FONTS" "unix fonts script missing feature guard"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" "SETTINGZSH_FEATURE_EDITOR" "unix editor script missing feature guard"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" "nvim" "unix editor script missing nvim deployment path"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" "config_merge.py" "unix editor script missing vimrc merge path"
require_contains "home/run_onchange_after_30-install-editor.sh.tmpl" '"$HOME/.vimrc"' "unix editor script missing vimrc target"
require_contains "home/run_onchange_after_40-install-private-ssh.sh.tmpl" "private ssh overlay" "unix private ssh script missing overlay status output"
require_contains "home/run_onchange_after_40-install-private-ssh.sh.tmpl" ".ssh/custom-paths" "unix private ssh script missing custom-paths target"
require_contains "home/run_onchange_after_40-install-private-ssh.sh.tmpl" "sops decrypt" "unix private ssh script missing sops decrypt support"

require_contains "home/run_once_before_10-install-base-packages.ps1.tmpl" "Terminal-Icons" "windows base script missing module setup"
require_contains "home/run_once_before_10-install-base-packages.ps1.tmpl" "winget" "windows base script missing winget usage"
require_contains "home/run_once_before_10-install-base-packages.ps1.tmpl" '$env:OS -eq "Windows_NT"' "windows base script missing PowerShell 5.1 compatible OS guard"
require_contains "home/run_once_before_20-install-fonts.ps1.tmpl" 'get (get . "features") "fonts"' "windows fonts script missing nested features.fonts lookup"
require_contains "home/run_once_before_20-install-fonts.ps1.tmpl" "MapleMonoNL-NF-CN.zip" "windows fonts script missing Maple download target"
require_contains "home/run_once_before_20-install-fonts.ps1.tmpl" "SETTINGZSH_INSTALL_FONTS" "windows fonts script missing feature guard"
require_contains "home/run_once_before_20-install-fonts.ps1.tmpl" '$env:OS -eq "Windows_NT"' "windows fonts script missing PowerShell 5.1 compatible OS guard"
require_contains "home/run_onchange_after_30-install-editor.ps1.tmpl" 'get (get . "features") "editor"' "windows editor script missing nested features.editor lookup"
require_contains "home/run_onchange_after_30-install-editor.ps1.tmpl" "SETTINGZSH_FEATURE_EDITOR" "windows editor script missing feature guard"
require_contains "home/run_onchange_after_30-install-editor.ps1.tmpl" "nvm" "windows editor script missing nvm/node setup"
require_contains "home/run_onchange_after_30-install-editor.ps1.tmpl" '$env:OS -eq "Windows_NT"' "windows editor script missing PowerShell 5.1 compatible OS guard"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" 'get (get . "features") "private_ssh_overlay"' "windows private ssh script missing nested features.private_ssh_overlay lookup"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" 'get (get . "overlay") "repo"' "windows private ssh script missing nested overlay.repo lookup"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" 'get (get . "overlay") "profile"' "windows private ssh script missing nested overlay.profile lookup"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" "SETTINGZSH_PRIVATE_SSH_OVERLAY" "windows private ssh script missing overlay feature guard"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" "custom-paths" "windows private ssh script missing custom-paths target"

for template in \
  "home/run_once_before_20-install-fonts.ps1.tmpl" \
  "home/run_onchange_after_30-install-editor.ps1.tmpl" \
  "home/run_onchange_after_40-install-private-ssh.ps1.tmpl"
do
  require_not_contains "$template" "install_fonts" "legacy install_fonts key still present in $template"
  require_not_contains "$template" "feature_editor" "legacy feature_editor key still present in $template"
  require_not_contains "$template" "private_ssh_overlay_repo" "legacy private_ssh_overlay_repo key still present in $template"
  require_not_contains "$template" "platform_profile" "legacy platform_profile key still present in $template"
done

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
mkdir -p "$dest_home" "$cache_dir"

cat > "$tmp_root/nested.toml" <<'EOF'
[data.features]
fonts = true
editor = true
private_ssh_overlay = true

[data.overlay]
repo = "/tmp/private-ssh-overlay"
profile = "testhost"
EOF

cat > "$tmp_root/windows-data.yaml" <<'EOF'
chezmoi:
  os: windows
EOF

render_template() {
  local template_path="$1"
  local output_path="$2"

  "$CHEZMOI_BIN" \
    --config "$tmp_root/nested.toml" \
    --override-data-file "$tmp_root/windows-data.yaml" \
    --cache "$cache_dir" \
    -S "$ROOT_DIR" \
    -D "$dest_home" \
    execute-template --file "$template_path" > "$output_path"
}

render_template "home/run_once_before_20-install-fonts.ps1.tmpl" "$tmp_root/fonts.ps1"
render_template "home/run_onchange_after_30-install-editor.ps1.tmpl" "$tmp_root/editor.ps1"
render_template "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" "$tmp_root/private-ssh.ps1"

require_contains "$tmp_root/fonts.ps1" '$installFontsDefault = "true"' "windows fonts render did not consume nested features.fonts"
require_contains "$tmp_root/editor.ps1" '$featureEditorDefault = "true"' "windows editor render did not consume nested features.editor"
require_contains "$tmp_root/private-ssh.ps1" '$overlayEnabledDefault = "true"' "windows private ssh render did not consume nested features.private_ssh_overlay"
require_contains "$tmp_root/private-ssh.ps1" '$overlayRepo = "/tmp/private-ssh-overlay"' "windows private ssh render did not consume nested overlay.repo"
require_contains "$tmp_root/private-ssh.ps1" '$profileDefault = "testhost"' "windows private ssh render did not consume nested overlay.profile"

echo "task4 scripts presence checks: ok"
