# settingZsh Adoption Guardrails Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 將 `settingZsh` 的既有系統導入路徑收斂成安全的 bootstrap ownership 與 adoption gate，並補上 interactive doctor、legacy import draft 與 secret manager 指南。

**Architecture:** `chezmoi` 繼續作為 public baseline 的主控制面，但不再直接擁有整份 `~/.zshrc`。新的 adoption flow 會先經過 blocking preflight、adopt report 與備份，再決定是否允許 bootstrap create / modify；interactive doctor 與 legacy import draft 分別作為 P1/P2 能力補上既有系統可觀測性與承接工具。

**Tech Stack:** chezmoi、Python、Bash、pytest、Zsh、Markdown

---

### Task 1: 將 `.zshrc` ownership 從 whole-file target 改成 bootstrap ownership

**Files:**
- Modify: `home/dot_zshrc.tmpl`
- Modify: `.chezmoi.toml.tmpl`
- Modify: `README.md`
- Test: `tests/chezmoi/test_source_state.sh`

**Step 1: Write the failing test**

```bash
if rg -q "dot_zshrc.tmpl" README.md; then
  :
fi

if ! rg -q "create_" README.md; then
  echo "README missing bootstrap ownership description"
  exit 1
fi
```

**Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_source_state.sh`
Expected: FAIL after adding assertions for bootstrap ownership because source state still models `.zshrc` as a whole-file target

**Step 3: Write minimal implementation**

```text
Describe `.zshrc` as a bootstrap-owned file.
Introduce create_/modify_ strategy in docs and source-state naming.
Keep bootstrap content minimal.
```

**Step 4: Run test to verify it passes**

Run: `bash tests/chezmoi/test_source_state.sh`
Expected: PASS with source-state checks updated for bootstrap ownership

**Step 5: Commit**

```bash
git add home/dot_zshrc.tmpl .chezmoi.toml.tmpl README.md tests/chezmoi/test_source_state.sh
git commit -m "refactor(shell): 收斂 zshrc ownership 為 bootstrap"
```

### Task 2: 新增 blocking preflight 能力

**Files:**
- Create: `lib/settingzsh/preflight.py`
- Modify: `lib/settingzsh/cli.py`
- Modify: `lib/settingzsh/state.py`
- Create: `tests/test_settingzsh_preflight.py`
- Modify: `README.md`
- Modify: `docs/architecture.md`

**Step 1: Write the failing test**

```python
def test_preflight_blocks_heavy_existing_zshrc(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()
    (home / ".zshrc").write_text("autoload -Uz compinit\nprecmd() { :; }\n", encoding="utf-8")

    result = run_preflight(home)

    assert result.status == "needs_adopt"
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_preflight.py`
Expected: FAIL because `preflight` does not exist yet

**Step 3: Write minimal implementation**

```python
def run_preflight(target_home: Path) -> PreflightResult:
    issues = []
    # inspect ~/.zshrc, classify safe / needs_adopt / broken_existing_shell
    return PreflightResult(status="needs_adopt", issues=issues)
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_preflight.py`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/preflight.py lib/settingzsh/cli.py lib/settingzsh/state.py tests/test_settingzsh_preflight.py README.md docs/architecture.md
git commit -m "feat(adopt): 新增 blocking preflight"
```

### Task 3: 新增 adopt existing shell 報告與備份流程

**Files:**
- Create: `lib/settingzsh/adopt.py`
- Modify: `lib/settingzsh/cli.py`
- Create: `tests/test_settingzsh_adopt.py`
- Create: `docs/adoption-guide.md`
- Modify: `README.md`

**Step 1: Write the failing test**

```python
def test_adopt_creates_backup_and_report(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()
    (home / ".zshrc").write_text("export PATH=\"$PATH:$HOME/.local/bin\"\n", encoding="utf-8")

    result = run_adopt(home)

    assert result.status == "reported"
    assert any(path.endswith(".bak") for path in result.modified_files)
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_adopt.py`
Expected: FAIL because adopt flow does not exist yet

**Step 3: Write minimal implementation**

```python
def run_adopt(target_home: Path) -> AdoptResult:
    # create backup, generate report summary, do not rewrite live shell
    return AdoptResult(status="reported", modified_files=[str(backup_path)])
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_adopt.py`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/adopt.py lib/settingzsh/cli.py tests/test_settingzsh_adopt.py docs/adoption-guide.md README.md
git commit -m "feat(adopt): 新增既有 shell 報告與備份流程"
```

### Task 4: 讓 setup / update 流程先走 adoption gate 再決定是否寫檔

**Files:**
- Modify: `lib/settingzsh/cli.py`
- Modify: `lib/settingzsh/reconcile.py`
- Modify: `tests/test_settingzsh_cli.py`
- Modify: `tests/test_settingzsh_reconcile.py`

**Step 1: Write the failing test**

```python
def test_setup_blocks_when_preflight_requires_adopt(tmp_path: Path, monkeypatch) -> None:
    home = tmp_path / "home"
    home.mkdir()

    monkeypatch.setattr("settingzsh.cli.run_preflight", lambda target_home: Fake(status="needs_adopt", issues=["heavy_existing_shell"]))
    result = run_setup(target_home=home)

    assert result.status == "needs_adopt"
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_cli.py tests/test_settingzsh_reconcile.py`
Expected: FAIL because setup/update do not consult preflight yet

**Step 3: Write minimal implementation**

```python
def run_setup(target_home: Path, *, validator=None) -> CommandResult:
    preflight = run_preflight(target_home)
    if preflight.status != "safe":
        return CommandResult(status=preflight.status, issues=preflight.issues)
    return run_reconcile(target_home=target_home, validator=validator)
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_cli.py tests/test_settingzsh_reconcile.py`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/cli.py lib/settingzsh/reconcile.py tests/test_settingzsh_cli.py tests/test_settingzsh_reconcile.py
git commit -m "refactor(setup): 導入 adoption gate"
```

### Task 5: 升級 doctor 為 interactive-aware shell doctor

**Files:**
- Modify: `lib/settingzsh/doctor.py`
- Modify: `lib/settingzsh/reconcile.py`
- Modify: `lib/settingzsh/state.py`
- Modify: `tests/test_settingzsh_doctor.py`
- Modify: `tests/test_settingzsh_reconcile.py`
- Modify: `README.md`

**Step 1: Write the failing test**

```python
def test_doctor_warns_when_interactive_shell_outputs_known_errors(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()
    (home / ".zshrc").write_text("export TEST_VAR=1\n", encoding="utf-8")

    result = run_doctor(target_home=home, validator=fake_interactive_validator)

    assert "interactive_shell_warning" in result.issues
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_doctor.py`
Expected: FAIL because doctor only does syntax validation today

**Step 3: Write minimal implementation**

```python
def run_doctor(...):
    # run syntax + interactive validation
    # record blocking / warning / info issues
    return DoctorResult(status="warn", issues=["interactive_shell_warning"], modified_files=[])
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_doctor.py`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/doctor.py lib/settingzsh/reconcile.py lib/settingzsh/state.py tests/test_settingzsh_doctor.py tests/test_settingzsh_reconcile.py README.md
git commit -m "feat(doctor): 補上 interactive shell 檢查"
```

### Task 6: 新增 legacy import draft 模式

**Files:**
- Create: `lib/settingzsh/legacy_import.py`
- Modify: `lib/settingzsh/cli.py`
- Create: `tests/test_settingzsh_legacy_import.py`
- Modify: `docs/adoption-guide.md`
- Modify: `README.md`

**Step 1: Write the failing test**

```python
def test_legacy_import_creates_draft_without_enabling_it(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()
    (home / ".zshrc").write_text("export OLD_VAR=1\n", encoding="utf-8")

    result = run_legacy_import(target_home=home, draft=True)

    draft = home / ".config" / "settingzsh" / "local.d" / "90-legacy-import.zsh.draft"
    assert result.status == "drafted"
    assert draft.exists()
    assert not (home / ".config" / "settingzsh" / "local.d" / "90-legacy-import.zsh").exists()
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_legacy_import.py`
Expected: FAIL because legacy import draft mode does not exist yet

**Step 3: Write minimal implementation**

```python
def run_legacy_import(target_home: Path, *, draft: bool = True) -> LegacyImportResult:
    # write .draft file only, do not enable live source
    return LegacyImportResult(status="drafted", modified_files=[str(draft_path)])
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_legacy_import.py`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/legacy_import.py lib/settingzsh/cli.py tests/test_settingzsh_legacy_import.py docs/adoption-guide.md README.md
git commit -m "feat(adopt): 新增 legacy import draft 模式"
```

### Task 7: 撰寫 keepassxc-cli 與 gopass 指南

**Files:**
- Create: `docs/secrets/keepassxc-cli.md`
- Create: `docs/secrets/gopass.md`
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `tests/test_settingzsh_docs.py`

**Step 1: Write the failing test**

```python
def test_secret_guides_exist() -> None:
    assert Path("docs/secrets/keepassxc-cli.md").exists()
    assert Path("docs/secrets/gopass.md").exists()
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_docs.py`
Expected: FAIL because the secret manager guides do not exist yet

**Step 3: Write minimal implementation**

```markdown
# keepassxc-cli

- 安裝
- 基本使用
- 何時適合 desktop
```

```markdown
# gopass

- 安裝
- 基本使用
- 何時適合 server
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_docs.py`
Expected: PASS

**Step 5: Commit**

```bash
git add docs/secrets/keepassxc-cli.md docs/secrets/gopass.md README.md docs/architecture.md tests/test_settingzsh_docs.py
git commit -m "docs(secrets): 補上 keepassxc-cli 與 gopass 指南"
```

### Task 8: 文件總整與最終驗證

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/adoption-guide.md`
- Modify: `tests/test_settingzsh_docs.py`

**Step 1: Write the failing test**

```bash
rg -q "fresh install" README.md
rg -q "existing machine" README.md
rg -q "adoption gate" docs/architecture.md
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_docs.py && bash tests/chezmoi/test_task1_scaffold.sh && bash tests/chezmoi/test_source_state.sh`
Expected: FAIL until docs are aligned with the new adoption/doctor/import design

**Step 3: Write minimal implementation**

```text
Update README and architecture docs to distinguish:
- fresh install
- existing machine adoption
- interactive doctor
- legacy import draft
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_docs.py && bash tests/chezmoi/test_task1_scaffold.sh && bash tests/chezmoi/test_source_state.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add README.md docs/architecture.md docs/adoption-guide.md tests/test_settingzsh_docs.py
git commit -m "docs(adopt): 對齊 adoption guardrails 設計"
```
