# settingZsh Final Target Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 將 `settingZsh` 收斂成 `chezmoi public baseline + adoption guardrails + custom private SSH repo + SOPS + age` 的最終架構。

**Architecture:** `settingZsh` repo 繼續作為跨平台 public baseline 與 adoption control plane；`valor-ssh` 轉為機器分層的 private SSH repo，透過 `SOPS + age` 保護 private files。實作重點不是增加更多 shell 自動修復，而是把 public/private 邊界、既有系統導入模型、SSH file secret 結構與操作文件一次收斂到終態。

**Tech Stack:** chezmoi、Python、Bash、pytest、Markdown、SOPS、age、OpenSSH

---

### Task 1: 對齊 settingZsh 文件，將最終架構升格為正式主模型

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/adoption-guide.md`
- Modify: `docs/secrets/keepassxc-cli.md`
- Modify: `docs/secrets/gopass.md`
- Test: `tests/test_settingzsh_docs.py`

**Step 1: Write the failing test**

```python
def test_docs_mention_final_target_architecture() -> None:
    readme = Path("README.md").read_text(encoding="utf-8")
    architecture = Path("docs/architecture.md").read_text(encoding="utf-8")

    assert "SOPS + age" in readme
    assert "custom private SSH repo" in architecture
    assert "shared-keys" in architecture
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_docs.py`
Expected: FAIL because current docs mention private repo, but not the full final-target secret repo model

**Step 3: Write minimal implementation**

```text
Update README and architecture docs to make the final target architecture explicit.
Clarify that runtime secrets are out of scope and SSH private repo uses SOPS + age.
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_docs.py`
Expected: PASS

**Step 5: Commit**

```bash
git add README.md docs/architecture.md docs/adoption-guide.md docs/secrets/keepassxc-cli.md docs/secrets/gopass.md tests/test_settingzsh_docs.py
git commit -m "docs(architecture): 對齊 final target 架構"
```

### Task 2: 收斂 public baseline 的 adoption gate 敘事與 CLI 語義

**Files:**
- Modify: `lib/settingzsh/cli.py`
- Modify: `lib/settingzsh/preflight.py`
- Modify: `lib/settingzsh/adopt.py`
- Modify: `lib/settingzsh/doctor.py`
- Modify: `tests/test_settingzsh_cli.py`
- Modify: `tests/test_settingzsh_preflight.py`
- Modify: `tests/test_settingzsh_doctor.py`

**Step 1: Write the failing test**

```python
def test_preflight_output_matches_safe_needs_adopt_or_broken() -> None:
    result = classify_preflight_result(...)
    assert result.status in {"safe", "needs_adopt", "broken_existing_shell"}
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_preflight.py tests/test_settingzsh_cli.py tests/test_settingzsh_doctor.py`
Expected: FAIL if status names, issue taxonomy, or doctor/preflight contract still drift from final docs

**Step 3: Write minimal implementation**

```text
Normalize CLI, preflight, adopt, and doctor outputs to the documented adoption gate model.
Ensure docs and code use the same status names and expectations.
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_preflight.py tests/test_settingzsh_cli.py tests/test_settingzsh_doctor.py`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/cli.py lib/settingzsh/preflight.py lib/settingzsh/adopt.py lib/settingzsh/doctor.py tests/test_settingzsh_cli.py tests/test_settingzsh_preflight.py tests/test_settingzsh_doctor.py
git commit -m "refactor(adopt): 對齊 adoption gate 最終語義"
```

### Task 3: 將 examples/valor-ssh-key 範本升級為 final-target private repo 範本

**Files:**
- Modify: `examples/valor-ssh-key/README.md`
- Create: `examples/valor-ssh-key/.sops.yaml.example`
- Create: `examples/valor-ssh-key/shared/config.d/10-common-private.conf`
- Create: `examples/valor-ssh-key/shared-keys/keys/README.md`
- Create: `examples/valor-ssh-key/macmini/config.d/90-private.conf`
- Create: `examples/valor-ssh-key/macmini/keys/.keep`
- Create: `examples/valor-ssh-key/macmini/custom-paths/sympasoft-macmini-ssh/.keep`
- Create: `examples/valor-ssh-key/valorpc/config.d/90-private.conf`
- Create: `examples/valor-ssh-key/valorpc/keys/.keep`
- Create: `examples/valor-ssh-key/valorpc/custom-paths/windows-imported/.keep`
- Modify: `tests/chezmoi/test_private_repo_template.sh`

**Step 1: Write the failing test**

```bash
test -f examples/valor-ssh-key/.sops.yaml.example
test -f examples/valor-ssh-key/shared-keys/keys/README.md
test -f examples/valor-ssh-key/macmini/config.d/90-private.conf
test -f examples/valor-ssh-key/valorpc/config.d/90-private.conf
```

**Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_private_repo_template.sh`
Expected: FAIL because the example repo still uses the older single-file template

**Step 3: Write minimal implementation**

```text
Expand the example private repo to the final directory model with shared, shared-keys, machine config, standard keys, and custom-paths placeholders.
```

**Step 4: Run test to verify it passes**

Run: `bash tests/chezmoi/test_private_repo_template.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add examples/valor-ssh-key tests/chezmoi/test_private_repo_template.sh
git commit -m "docs(ssh): 升級 private repo 範本結構"
```

### Task 4: 為 SOPS + age 補正式指南與操作範本

**Files:**
- Create: `docs/secrets/sops-age.md`
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `examples/valor-ssh-key/README.md`
- Modify: `tests/test_settingzsh_docs.py`

**Step 1: Write the failing test**

```python
def test_docs_include_sops_age_workflow() -> None:
    guide = Path("docs/secrets/sops-age.md").read_text(encoding="utf-8")
    assert "owner" in guide
    assert "recovery" in guide
    assert "updatekeys" in guide
    assert "rotate" in guide
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_docs.py`
Expected: FAIL because `docs/secrets/sops-age.md` does not exist yet

**Step 3: Write minimal implementation**

```text
Document how SOPS + age fits into the final architecture, including recipient model, .sops.yaml, authoring, materialization, rotation, and recovery.
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_docs.py`
Expected: PASS

**Step 5: Commit**

```bash
git add docs/secrets/sops-age.md README.md docs/architecture.md examples/valor-ssh-key/README.md tests/test_settingzsh_docs.py
git commit -m "docs(secrets): 新增 sops 與 age 指南"
```

### Task 5: 重構 valor-ssh repo 結構，拆分單一 90-private.conf

**Files:**
- Modify: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/README.md`
- Create: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/.sops.yaml`
- Create: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/shared/config.d/10-common-private.conf`
- Create: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/shared-keys/keys/README.md`
- Create: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/macmini/config.d/90-private.conf`
- Create: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/valorpc/config.d/90-private.conf`
- Create: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/macmini/keys/`
- Create: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/macmini/custom-paths/sympasoft-macmini-ssh/`
- Create: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/valorpc/keys/`
- Create: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/valorpc/custom-paths/windows-imported/`
- Delete: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/.ssh/config.d/90-private.conf`

**Step 1: Write the failing test**

```bash
test -f /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/macmini/config.d/90-private.conf
test -f /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/valorpc/config.d/90-private.conf
test ! -f /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/.ssh/config.d/90-private.conf
```

**Step 2: Run test to verify it fails**

Run: `test -f /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/.ssh/config.d/90-private.conf`
Expected: PASS initially, which confirms the old monolithic file still exists and refactor has not happened

**Step 3: Write minimal implementation**

```text
Split host entries by machine.
Keep macOS-specific options only in macmini config.
Move custom-path hosts to machine-specific custom-path conventions.
Add .sops.yaml and directory README markers.
```

**Step 4: Run test to verify it passes**

Run: `ssh -G Macmini-Docker-debian >/dev/null`
Expected: PASS after user updates include paths and materializes files into the correct target locations

**Step 5: Commit**

```bash
git -C /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh add .
git -C /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh commit -m "refactor(ssh): 重組 private repo 結構"
```

### Task 6: 收斂 SSH config 規則與 host hygiene

**Files:**
- Modify: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/macmini/config.d/90-private.conf`
- Modify: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/valorpc/config.d/90-private.conf`
- Modify: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/shared/config.d/10-common-private.conf`

**Step 1: Write the failing test**

```bash
! rg -n "~\\\\.ssh\\\\" /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/macmini/config.d/90-private.conf /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/valorpc/config.d/90-private.conf
rg -n "IdentityFile" /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh | cat
```

**Step 2: Run test to verify it fails**

Run: `rg -n "~\\\\.ssh\\\\" /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh`
Expected: FAIL while Windows-style path syntax still exists in shared configs

**Step 3: Write minimal implementation**

```text
Normalize IdentityFile path style.
Add IdentitiesOnly yes where IdentityFile is explicit.
Trim ForwardAgent yes to only the hosts that require it.
Use IgnoreUnknown UseKeychain before any macOS-only UseKeychain usage in shared-readable files.
```

**Step 4: Run test to verify it passes**

Run: `rg -n "~\\\\.ssh\\\\" /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh`
Expected: No matches in active config files

**Step 5: Commit**

```bash
git -C /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh add .
git -C /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh commit -m "refactor(ssh): 收斂 host 與 key 規則"
```

### Task 7: 補上 final-target 驗證腳本與回歸檢查

**Files:**
- Create: `tests/chezmoi/test_final_target_docs.sh`
- Modify: `tests/test_settingzsh_docs.py`
- Create: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/scripts/check-ssh-config.sh`

**Step 1: Write the failing test**

```bash
test -f tests/chezmoi/test_final_target_docs.sh
test -f /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/scripts/check-ssh-config.sh
```

**Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_final_target_docs.sh`
Expected: FAIL because the final-target verification script does not exist yet

**Step 3: Write minimal implementation**

```text
Add one docs-focused check in settingZsh and one SSH-config-focused check in valor-ssh.
Keep verification lightweight and deterministic.
```

**Step 4: Run test to verify it passes**

Run: `bash tests/chezmoi/test_final_target_docs.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/chezmoi/test_final_target_docs.sh tests/test_settingzsh_docs.py
git -C /Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh add scripts/check-ssh-config.sh
git commit -m "test(docs): 補上 final target 驗證"
```

### Task 8: 執行整體驗證並整理操作手冊

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `/Users/arlen/Documents/syncthing/backup/server/Code/valor-ssh/README.md`
- Modify: `tests/TEST_REPORT.md`

**Step 1: Write the failing test**

```bash
uv run pytest -q tests/test_settingzsh_docs.py
bash tests/chezmoi/test_private_repo_template.sh
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_docs.py`
Expected: FAIL if docs, examples, or secret-repo narrative still drift

**Step 3: Write minimal implementation**

```text
Update final user-facing docs to match the implemented final target.
Add verification notes and known non-goals.
```

**Step 4: Run test to verify it passes**

Run:
- `uv run pytest -q tests/test_settingzsh_docs.py tests/test_settingzsh_*.py`
- `bash tests/chezmoi/test_private_repo_template.sh`
- `bash tests/chezmoi/test_source_state.sh`
- `bash tests/chezmoi/test_task1_scaffold.sh`
- `bash tests/chezmoi/test_linux_fallback.sh`

Expected: PASS

**Step 5: Commit**

```bash
git add README.md docs/architecture.md tests/TEST_REPORT.md
git commit -m "docs(readme): 收斂 final target 操作手冊"
```
