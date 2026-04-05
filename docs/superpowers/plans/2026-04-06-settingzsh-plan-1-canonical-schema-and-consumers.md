# settingZsh Canonical Schema and Consumers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 `.chezmoidata` 單一 schema，並讓 `home/` 下的 `chezmoi` templates 與 `run_*` scripts 全部改讀 nested `features` / `overlay` / `artifacts` 模型。

**Architecture:** `home/.chezmoidata/` 成為唯一設定真相來源。`.chezmoi.toml.tmpl` 只提供使用者可覆寫欄位，改用 `[data.features]` 與 `[data.overlay]`。所有 `run_*` 與 `.chezmoiexternal.toml.tmpl` 停止讀 top-level flags，改讀 nested data；Linux fallback URL 改由 template 展開的 `os + arch` artifact map 提供。

**Tech Stack:** chezmoi templates, bash, PowerShell, pytest, shell smoke tests

---

### Task 1: 建立 canonical schema 測試與使用者覆寫入口

**Files:**
- Create: `tests/test_settingzsh_schema.py`
- Modify: `home/.chezmoi.toml.tmpl`
- Create: `home/.chezmoidata/defaults.yaml`
- Create: `home/.chezmoidata/artifacts.yaml`
- Delete: `home/.chezmoidata/common.yaml`
- Modify: `tests/chezmoi/test_apply_smoke.sh`
- Test: `tests/test_settingzsh_schema.py`
- Test: `tests/chezmoi/test_apply_smoke.sh`

- [ ] **Step 1: Write the failing test**

```python
from __future__ import annotations

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_chezmoi_toml_uses_nested_features_and_overlay() -> None:
    content = (PROJECT_ROOT / "home" / ".chezmoi.toml.tmpl").read_text(encoding="utf-8")

    assert "[data.features]" in content
    assert "[data.overlay]" in content
    assert "feature_editor" not in content
    assert "install_fonts" not in content
    assert "private_ssh_overlay_repo" not in content


def test_artifact_schema_contains_linux_x86_64_and_arm64_pairs() -> None:
    content = (PROJECT_ROOT / "home" / ".chezmoidata" / "artifacts.yaml").read_text(
        encoding="utf-8"
    )

    for tool in ("ripgrep", "fd", "neovim", "lazygit"):
        assert f"{tool}:" in content
    assert "x86_64:" in content
    assert "arm64:" in content


def test_legacy_common_data_file_is_removed() -> None:
    assert not (PROJECT_ROOT / "home" / ".chezmoidata" / "common.yaml").exists()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_schema.py`
Expected: FAIL because `tests/test_settingzsh_schema.py` does not exist and `home/.chezmoidata/artifacts.yaml` does not exist.

- [ ] **Step 3: Write the canonical defaults and user override entry point**

```toml
# home/.chezmoi.toml.tmpl
# settingZsh canonical chezmoi defaults

[data.features]
editor = false
fonts = true
private_ssh_overlay = false

[data.overlay]
repo = ""
profile = "auto"

[diff]
pager = "auto"
```

```yaml
# home/.chezmoidata/defaults.yaml
features:
  editor: false
  fonts: true
  private_ssh_overlay: false

overlay:
  repo: ""
  profile: "auto"
```

```bash
git rm home/.chezmoidata/common.yaml
```

```yaml
# home/.chezmoidata/artifacts.yaml
artifacts:
  ripgrep:
    linux:
      x86_64: "https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz"
      arm64: "https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-aarch64-unknown-linux-musl.tar.gz"
  fd:
    linux:
      x86_64: "https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-musl.tar.gz"
      arm64: "https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-aarch64-unknown-linux-musl.tar.gz"
  neovim:
    linux:
      x86_64: "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
      arm64: "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
  lazygit:
    linux:
      x86_64: "https://github.com/jesseduffield/lazygit/releases/download/v0.44.1/lazygit_0.44.1_Linux_x86_64.tar.gz"
      arm64: "https://github.com/jesseduffield/lazygit/releases/download/v0.44.1/lazygit_0.44.1_Linux_arm64.tar.gz"
```

```bash
# tests/chezmoi/test_apply_smoke.sh
cat > "$tmp_root/chezmoi.toml" <<'EOF'
[data.features]
editor = false
fonts = false
private_ssh_overlay = false

[data.overlay]
profile = "auto"
repo = ""
EOF
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uv run pytest -q tests/test_settingzsh_schema.py`
Expected: PASS

Run: `bash tests/chezmoi/test_apply_smoke.sh`
Expected: `chezmoi apply smoke: ok`

- [ ] **Step 5: Commit**

```bash
git add home/.chezmoi.toml.tmpl home/.chezmoidata/defaults.yaml home/.chezmoidata/artifacts.yaml tests/test_settingzsh_schema.py tests/chezmoi/test_apply_smoke.sh
git rm home/.chezmoidata/common.yaml
git commit -m "refactor(schema): 收斂 chezmoi 巢狀設定模型"
```

### Task 2: 讓 Unix scripts 與 externals 改讀 canonical nested schema

**Files:**
- Modify: `home/.chezmoiexternal.toml.tmpl`
- Modify: `home/run_once_before_20-install-fonts.sh.tmpl`
- Modify: `home/run_onchange_after_30-install-editor.sh.tmpl`
- Modify: `home/run_onchange_after_40-install-private-ssh.sh.tmpl`
- Modify: `tests/chezmoi/test_fonts_feature_gating.sh`
- Modify: `tests/chezmoi/test_linux_fallback.sh`
- Modify: `tests/chezmoi/test_ssh_overlay.sh`
- Test: `tests/chezmoi/test_fonts_feature_gating.sh`
- Test: `tests/chezmoi/test_linux_fallback.sh`
- Test: `tests/chezmoi/test_ssh_overlay.sh`

- [ ] **Step 1: Write the failing tests**

```bash
# tests/chezmoi/test_linux_fallback.sh
require_contains "$EDITOR_SCRIPT" "detect_arch()" "editor script missing architecture detector"
require_contains "$EDITOR_SCRIPT" "RIPGREP_URL_ARM64" "editor script missing arm64 ripgrep artifact"
require_contains "$EDITOR_SCRIPT" "FD_URL_ARM64" "editor script missing arm64 fd artifact"
require_contains "$EDITOR_SCRIPT" "NVIM_URL_ARM64" "editor script missing arm64 neovim artifact"
require_contains "$EDITOR_SCRIPT" "LAZYGIT_URL_ARM64" "editor script missing arm64 lazygit artifact"
```

```bash
# tests/chezmoi/test_fonts_feature_gating.sh
require_contains "$SCRIPT" 'get (get . "features") "fonts"' "fonts script still reads legacy top-level flag"
```

```bash
# tests/chezmoi/test_ssh_overlay.sh
require_contains "$SCRIPT" 'get (get . "features") "private_ssh_overlay"' "overlay script still reads legacy top-level flag"
require_contains "$SCRIPT" 'get (get . "overlay") "repo"' "overlay script still reads legacy repo key"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/chezmoi/test_fonts_feature_gating.sh`
Expected: FAIL with nested feature lookup assertion.

Run: `bash tests/chezmoi/test_linux_fallback.sh`
Expected: FAIL because the editor script does not expose `detect_arch()` or arm64 artifact variables.

Run: `bash tests/chezmoi/test_ssh_overlay.sh`
Expected: FAIL with nested overlay lookup assertion.

- [ ] **Step 3: Update Unix scripts and externals to use nested data**

```bash
# home/run_once_before_20-install-fonts.sh.tmpl
INSTALL_FONTS_DEFAULT="{{ if (get (get . \"features\") \"fonts\") }}true{{ else }}false{{ end }}"
```

```bash
# home/run_onchange_after_30-install-editor.sh.tmpl
FEATURE_EDITOR_DEFAULT="{{ if (get (get . \"features\") \"editor\") }}true{{ else }}false{{ end }}"

RIPGREP_URL_X86_64="{{ index . \"artifacts\" \"ripgrep\" \"linux\" \"x86_64\" }}"
RIPGREP_URL_ARM64="{{ index . \"artifacts\" \"ripgrep\" \"linux\" \"arm64\" }}"
FD_URL_X86_64="{{ index . \"artifacts\" \"fd\" \"linux\" \"x86_64\" }}"
FD_URL_ARM64="{{ index . \"artifacts\" \"fd\" \"linux\" \"arm64\" }}"
NVIM_URL_X86_64="{{ index . \"artifacts\" \"neovim\" \"linux\" \"x86_64\" }}"
NVIM_URL_ARM64="{{ index . \"artifacts\" \"neovim\" \"linux\" \"arm64\" }}"
LAZYGIT_URL_X86_64="{{ index . \"artifacts\" \"lazygit\" \"linux\" \"x86_64\" }}"
LAZYGIT_URL_ARM64="{{ index . \"artifacts\" \"lazygit\" \"linux\" \"arm64\" }}"

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf 'x86_64\n' ;;
    aarch64|arm64) printf 'arm64\n' ;;
    *) printf 'unsupported\n' ;;
  esac
}
```

```bash
# home/run_onchange_after_40-install-private-ssh.sh.tmpl
OVERLAY_ENABLED_DEFAULT="{{ if (get (get . \"features\") \"private_ssh_overlay\") }}true{{ else }}false{{ end }}"
OVERLAY_REPO="{{ get (get . \"overlay\") \"repo\" }}"
PROFILE_DEFAULT="{{ get (get . \"overlay\") \"profile\" }}"
```

```toml
# home/.chezmoiexternal.toml.tmpl
{{- $overlayRepo := get (get . "overlay") "repo" -}}
{{- if and (get (get . "features") "private_ssh_overlay") $overlayRepo }}
[".local/share/settingzsh/private-ssh-overlay"]
    type = "git-repo"
    url = {{ $overlayRepo | quote }}
    clone.args = ["--depth", "1"]
    pull.args = ["--ff-only"]
{{- end }}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/chezmoi/test_fonts_feature_gating.sh`
Expected: `fonts feature gating: ok`

Run: `bash tests/chezmoi/test_linux_fallback.sh`
Expected: `task5 linux fallback checks: ok`

Run: `bash tests/chezmoi/test_ssh_overlay.sh`
Expected: `private ssh overlay checks: ok`

- [ ] **Step 5: Commit**

```bash
git add home/.chezmoiexternal.toml.tmpl home/run_once_before_20-install-fonts.sh.tmpl home/run_onchange_after_30-install-editor.sh.tmpl home/run_onchange_after_40-install-private-ssh.sh.tmpl tests/chezmoi/test_fonts_feature_gating.sh tests/chezmoi/test_linux_fallback.sh tests/chezmoi/test_ssh_overlay.sh
git commit -m "refactor(chezmoi): 讓腳本改讀巢狀 schema"
```

### Task 3: 同步 PowerShell consumers 與 cross-platform config tests

**Files:**
- Modify: `home/run_once_before_20-install-fonts.ps1.tmpl`
- Modify: `home/run_onchange_after_30-install-editor.ps1.tmpl`
- Modify: `home/run_onchange_after_40-install-private-ssh.ps1.tmpl`
- Modify: `tests/chezmoi/test_scripts_presence.sh`
- Test: `tests/chezmoi/test_scripts_presence.sh`
- Test: `tests/chezmoi/test_platform_script_gating.sh`

- [ ] **Step 1: Write the failing tests**

```bash
# tests/chezmoi/test_scripts_presence.sh
require_contains "home/run_once_before_20-install-fonts.ps1.tmpl" 'get (get . "features") "fonts"' "fonts PowerShell script still reads legacy top-level flag"
require_contains "home/run_onchange_after_30-install-editor.ps1.tmpl" 'get (get . "features") "editor"' "editor PowerShell script still reads legacy top-level flag"
require_contains "home/run_onchange_after_40-install-private-ssh.ps1.tmpl" 'get (get . "overlay") "repo"' "overlay PowerShell script still reads legacy overlay repo key"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_scripts_presence.sh`
Expected: FAIL with legacy top-level flag assertion.

- [ ] **Step 3: Update PowerShell templates to use nested data**

```powershell
# home/run_once_before_20-install-fonts.ps1.tmpl
$installFontsDefault = "{{ if (get (get . "features") "fonts") }}true{{ else }}false{{ end }}"
```

```powershell
# home/run_onchange_after_30-install-editor.ps1.tmpl
$featureEditorDefault = "{{ if (get (get . "features") "editor") }}true{{ else }}false{{ end }}"
```

```powershell
# home/run_onchange_after_40-install-private-ssh.ps1.tmpl
$overlayEnabledDefault = "{{ if (get (get . "features") "private_ssh_overlay") }}true{{ else }}false{{ end }}"
$overlayRepo = "{{ get (get . "overlay") "repo" }}"
$profileDefault = "{{ get (get . "overlay") "profile" }}"
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/chezmoi/test_scripts_presence.sh`
Expected: `script presence checks: ok`

Run: `bash tests/chezmoi/test_platform_script_gating.sh`
Expected: `platform script gating: ok`

- [ ] **Step 5: Commit**

```bash
git add home/run_once_before_20-install-fonts.ps1.tmpl home/run_onchange_after_30-install-editor.ps1.tmpl home/run_onchange_after_40-install-private-ssh.ps1.tmpl tests/chezmoi/test_scripts_presence.sh
git commit -m "refactor(powershell): 對齊巢狀 chezmoi schema"
```
