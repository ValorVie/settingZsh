# settingZsh Chezmoi Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 將 `settingZsh` 的主控制面遷移到 `chezmoi`，同時保留現有 macOS / Linux / Windows 的可交付結果，並導入 `public baseline + private SSH overlay`。

**Architecture:** `public repo` 作為唯一主入口與 baseline source of truth，負責通用 dotfiles、平台 scripts、feature flags 與 `.ssh/config` 主骨架；`private repo` 僅作為 `~/.ssh/**` 的受控 overlay feed。部署採兩階段：先套用 public baseline，再於使用者完成 Git 驗證後套用 private SSH overlay。

**Tech Stack:** chezmoi、Bash、PowerShell、YAML、TOML、Git、OpenSSH

---

### Task 1: 建立 capability parity matrix 與 chezmoi 遷移骨架

**Files:**
- Create: `docs/plans/2026-03-15-settingzsh-capability-parity.md`
- Create: `.chezmoi.toml.tmpl`
- Create: `.chezmoidata/common.yaml`
- Create: `.chezmoidata/macos.yaml`
- Create: `.chezmoidata/linux.yaml`
- Create: `.chezmoidata/windows.yaml`
- Modify: `README.md`

**Step 1: Write the failing test**

```bash
if ! test -f docs/plans/2026-03-15-settingzsh-capability-parity.md; then
  echo "missing capability parity matrix"
  exit 1
fi

if ! test -f .chezmoi.toml.tmpl; then
  echo "missing chezmoi root config"
  exit 1
fi
```

**Step 2: Run test to verify it fails**

Run: `bash -c 'test -f docs/plans/2026-03-15-settingzsh-capability-parity.md && test -f .chezmoi.toml.tmpl'`
Expected: FAIL because the chezmoi scaffold does not exist yet

**Step 3: Write minimal implementation**

```toml
[data]
feature_editor = false
private_ssh_overlay = false
```

```yaml
platform:
  name: common
```

**Step 4: Run test to verify it passes**

Run: `bash -c 'test -f docs/plans/2026-03-15-settingzsh-capability-parity.md && test -f .chezmoi.toml.tmpl && test -f .chezmoidata/common.yaml'`
Expected: PASS

**Step 5: Commit**

```bash
git add docs/plans/2026-03-15-settingzsh-capability-parity.md .chezmoi.toml.tmpl .chezmoidata/common.yaml .chezmoidata/macos.yaml .chezmoidata/linux.yaml .chezmoidata/windows.yaml README.md
git commit -m "feat(chezmoi): 建立遷移骨架與 parity matrix"
```

### Task 2: 建立 public baseline 的 shell / profile source state

**Files:**
- Create: `home/dot_zshrc.tmpl`
- Create: `home/private_dot_ssh/config.tmpl`
- Create: `home/private_dot_ssh/config.d/10-common.conf.tmpl`
- Create: `home/dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl`
- Modify: `README.md`
- Test: `tests/chezmoi/test_source_state.sh`

**Step 1: Write the failing test**

```bash
test -f home/dot_zshrc.tmpl
test -f home/private_dot_ssh/config.tmpl
test -f home/dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl
```

**Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_source_state.sh`
Expected: FAIL because the public baseline files do not exist

**Step 3: Write minimal implementation**

```zsh
# managed by chezmoi
source "$HOME/.config/settingzsh/init.zsh"
```

```sshconfig
Host *
  ServerAliveInterval 60

Include ~/.ssh/config.d/*.conf
```

**Step 4: Run test to verify it passes**

Run: `bash tests/chezmoi/test_source_state.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add home/dot_zshrc.tmpl home/private_dot_ssh/config.tmpl home/private_dot_ssh/config.d/10-common.conf.tmpl home/dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl tests/chezmoi/test_source_state.sh README.md
git commit -m "feat(chezmoi): 建立 public baseline source state"
```

### Task 3: 移植 Zsh baseline、Zinit 與預設插件集合

**Files:**
- Create: `home/dot_config/settingzsh/init.zsh.tmpl`
- Create: `home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl`
- Create: `home/dot_config/settingzsh/managed.d/40-editor.zsh.tmpl`
- Modify: `templates/zshrc_base_mac.zsh`
- Modify: `templates/zshrc_base_linux.zsh`
- Test: `tests/chezmoi/test_zsh_baseline.sh`

**Step 1: Write the failing test**

```bash
grep -q "zinit" home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl
grep -q "powerlevel10k" home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl
grep -q "fzf-tab" home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl
```

**Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_zsh_baseline.sh`
Expected: FAIL because the chezmoi Zsh baseline has not been ported

**Step 3: Write minimal implementation**

```zsh
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
zinit ice depth=1
zinit light romkatv/powerlevel10k
```

**Step 4: Run test to verify it passes**

Run: `bash tests/chezmoi/test_zsh_baseline.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add home/dot_config/settingzsh/init.zsh.tmpl home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl home/dot_config/settingzsh/managed.d/40-editor.zsh.tmpl templates/zshrc_base_mac.zsh templates/zshrc_base_linux.zsh tests/chezmoi/test_zsh_baseline.sh
git commit -m "feat(shell): 移植 zsh baseline 到 chezmoi"
```

### Task 4: 以 run scripts 重建平台安裝能力

**Files:**
- Create: `run_once_before_10-install-base-packages.sh.tmpl`
- Create: `run_once_before_20-install-fonts.sh.tmpl`
- Create: `run_onchange_after_30-install-editor.sh.tmpl`
- Create: `run_once_before_10-install-base-packages.ps1.tmpl`
- Create: `run_once_before_20-install-fonts.ps1.tmpl`
- Modify: `README.md`
- Test: `tests/chezmoi/test_scripts_presence.sh`

**Step 1: Write the failing test**

```bash
test -f run_once_before_10-install-base-packages.sh.tmpl
test -f run_once_before_20-install-fonts.sh.tmpl
test -f run_once_before_10-install-base-packages.ps1.tmpl
```

**Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_scripts_presence.sh`
Expected: FAIL because the chezmoi run scripts do not exist

**Step 3: Write minimal implementation**

```bash
case "{{ .chezmoi.os }}" in
  darwin) brew install zsh git unzip xz ;;
  linux) echo "linux base install" ;;
esac
```

```powershell
if (Get-Command winget -ErrorAction SilentlyContinue) {
  winget install junegunn.fzf --accept-source-agreements --accept-package-agreements
}
```

**Step 4: Run test to verify it passes**

Run: `bash tests/chezmoi/test_scripts_presence.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add run_once_before_10-install-base-packages.sh.tmpl run_once_before_20-install-fonts.sh.tmpl run_onchange_after_30-install-editor.sh.tmpl run_once_before_10-install-base-packages.ps1.tmpl run_once_before_20-install-fonts.ps1.tmpl tests/chezmoi/test_scripts_presence.sh README.md
git commit -m "feat(setup): 用 chezmoi scripts 重建平台安裝"
```

### Task 5: 補齊 Linux 無 sudo fallback 與 Windows profile/modules parity

**Files:**
- Modify: `run_once_before_10-install-base-packages.sh.tmpl`
- Modify: `run_onchange_after_30-install-editor.sh.tmpl`
- Modify: `run_once_before_10-install-base-packages.ps1.tmpl`
- Modify: `home/dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl`
- Test: `tests/chezmoi/test_linux_fallback.sh`
- Test: `tests/chezmoi/test_windows_profile.ps1`

**Step 1: Write the failing test**

```bash
grep -q "ripgrep" run_onchange_after_30-install-editor.sh.tmpl
grep -q "fd" run_onchange_after_30-install-editor.sh.tmpl
```

```powershell
Select-String -Path home/dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl -Pattern "Terminal-Icons","ZLocation","PSFzf"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_linux_fallback.sh && pwsh -File tests/chezmoi/test_windows_profile.ps1`
Expected: FAIL because fallback and module parity are not fully ported

**Step 3: Write minimal implementation**

```bash
if ! sudo -n true 2>/dev/null; then
  echo "no sudo fallback"
fi
```

```powershell
Import-Module Terminal-Icons
Import-Module ZLocation
Import-Module PSFzf
```

**Step 4: Run test to verify it passes**

Run: `bash tests/chezmoi/test_linux_fallback.sh && pwsh -File tests/chezmoi/test_windows_profile.ps1`
Expected: PASS

**Step 5: Commit**

```bash
git add run_once_before_10-install-base-packages.sh.tmpl run_onchange_after_30-install-editor.sh.tmpl run_once_before_10-install-base-packages.ps1.tmpl home/dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl tests/chezmoi/test_linux_fallback.sh tests/chezmoi/test_windows_profile.ps1
git commit -m "feat(platform): 補齊 linux fallback 與 windows parity"
```

### Task 6: 導入 editor feature state 與備份策略

**Files:**
- Create: `home/.chezmoidata/features.yaml.tmpl`
- Modify: `run_onchange_after_30-install-editor.sh.tmpl`
- Modify: `run_once_before_10-install-base-packages.ps1.tmpl`
- Modify: `README.md`
- Test: `tests/chezmoi/test_feature_gating.sh`

**Step 1: Write the failing test**

```bash
grep -q "feature_editor" .chezmoi.toml.tmpl
grep -q "nvim.bak" run_onchange_after_30-install-editor.sh.tmpl
```

**Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_feature_gating.sh`
Expected: FAIL because feature gating and backup behavior are not yet explicit

**Step 3: Write minimal implementation**

```bash
if [ "{{ .feature_editor }}" != "true" ]; then
  exit 0
fi
```

```bash
mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
```

**Step 4: Run test to verify it passes**

Run: `bash tests/chezmoi/test_feature_gating.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add home/.chezmoidata/features.yaml.tmpl .chezmoi.toml.tmpl run_onchange_after_30-install-editor.sh.tmpl run_once_before_10-install-base-packages.ps1.tmpl tests/chezmoi/test_feature_gating.sh README.md
git commit -m "feat(editor): 導入 feature gating 與備份策略"
```

### Task 7: 建立 private SSH overlay 第二階段流程

**Files:**
- Create: `.chezmoiexternal.toml.tmpl`
- Create: `run_onchange_after_40-install-private-ssh.sh.tmpl`
- Create: `run_onchange_after_40-install-private-ssh.ps1.tmpl`
- Modify: `home/private_dot_ssh/config.tmpl`
- Modify: `docs/plans/2026-03-15-settingzsh-capability-parity.md`
- Test: `tests/chezmoi/test_ssh_overlay.sh`

**Step 1: Write the failing test**

```bash
grep -q "Include ~/.ssh/config.d/*.conf" home/private_dot_ssh/config.tmpl
grep -q "private_ssh_overlay" .chezmoiexternal.toml.tmpl
```

**Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_ssh_overlay.sh`
Expected: FAIL because the private overlay flow does not exist

**Step 3: Write minimal implementation**

```toml
["private-ssh"]
type = "git-repo"
url = "{{ .private_ssh_overlay_repo }}"
refreshPeriod = "168h"
```

```bash
install -m 600 "$SOURCE_DIR/id_ed25519" "$HOME/.ssh/id_ed25519"
```

**Step 4: Run test to verify it passes**

Run: `bash tests/chezmoi/test_ssh_overlay.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add .chezmoiexternal.toml.tmpl run_onchange_after_40-install-private-ssh.sh.tmpl run_onchange_after_40-install-private-ssh.ps1.tmpl home/private_dot_ssh/config.tmpl docs/plans/2026-03-15-settingzsh-capability-parity.md tests/chezmoi/test_ssh_overlay.sh
git commit -m "feat(ssh): 建立 private overlay 第二階段流程"
```

### Task 8: 補齊文件、驗收腳本與舊流程退場策略

**Files:**
- Modify: `README.md`
- Create: `docs/chezmoi-migration.md`
- Create: `tests/chezmoi/test_apply_smoke.sh`
- Create: `tests/chezmoi/test_apply_smoke.ps1`
- Modify: `docs/plans/2026-03-15-settingzsh-capability-parity.md`
- Modify: `docs/plans/2026-03-15-settingzsh-chezmoi-migration-design.md`

**Step 1: Write the failing test**

```bash
test -f docs/chezmoi-migration.md
test -f tests/chezmoi/test_apply_smoke.sh
```

**Step 2: Run test to verify it fails**

Run: `bash -c 'test -f docs/chezmoi-migration.md && test -f tests/chezmoi/test_apply_smoke.sh'`
Expected: FAIL because migration docs and smoke checks are missing

**Step 3: Write minimal implementation**

```markdown
1. Run `chezmoi init --apply`
2. Verify shell/profile
3. Complete manual auth
4. Run the private SSH overlay step
```

```bash
chezmoi apply --dry-run
```

**Step 4: Run test to verify it passes**

Run: `bash -c 'test -f docs/chezmoi-migration.md && test -f tests/chezmoi/test_apply_smoke.sh'`
Expected: PASS

**Step 5: Commit**

```bash
git add README.md docs/chezmoi-migration.md tests/chezmoi/test_apply_smoke.sh tests/chezmoi/test_apply_smoke.ps1 docs/plans/2026-03-15-settingzsh-capability-parity.md docs/plans/2026-03-15-settingzsh-chezmoi-migration-design.md
git commit -m "docs(chezmoi): 補齊遷移指南與驗收流程"
```
