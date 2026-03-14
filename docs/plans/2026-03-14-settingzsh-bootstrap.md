# settingZsh Bootstrap 化重構 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 將 `settingZsh` 對 `.zshrc` 的責任收斂為最小 bootstrap，並以 Python + uv 管理本工具自己的 shell 片段與診斷流程。

**Architecture:** 保留現有 shell 腳本作為平台入口，但把 shell 狀態管理搬到新的 Python CLI。`.zshrc` 不再由 full-file merge 主導，而是只保留 bootstrap，managed 內容改由 `~/.config/settingzsh/managed.d/*.zsh` 載入。遷移與修復只處理 `settingZsh` 自己留下的內容。

**Tech Stack:** Bash、Python 3.10+、uv、pytest、zsh

---

### Task 1: 建立 Python CLI 骨架

**Files:**
- Create: `lib/settingzsh/__init__.py`
- Create: `lib/settingzsh/cli.py`
- Create: `lib/settingzsh/state.py`
- Modify: `lib/pyproject.toml`
- Test: `tests/test_settingzsh_cli.py`

**Step 1: Write the failing test**

```python
from settingzsh.cli import build_parser


def test_cli_exposes_expected_commands():
    parser = build_parser()
    choices = parser._subparsers._group_actions[0].choices
    assert {"setup", "update", "doctor", "migrate", "reconcile"} <= set(choices)
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_cli.py::test_cli_exposes_expected_commands -v`
Expected: FAIL with `ModuleNotFoundError` or missing parser implementation

**Step 3: Write minimal implementation**

```python
def build_parser():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    for name in ("setup", "update", "doctor", "migrate", "reconcile"):
        subparsers.add_parser(name)
    return parser
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_cli.py::test_cli_exposes_expected_commands -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/__init__.py lib/settingzsh/cli.py lib/settingzsh/state.py lib/pyproject.toml tests/test_settingzsh_cli.py
git commit -m "重構(cli): 建立 settingzsh Python 命令骨架"
```

### Task 2: 產生 bootstrap 與 managed fragments

**Files:**
- Create: `lib/settingzsh/shellgen.py`
- Create: `lib/settingzsh/bootstrap.py`
- Modify: `lib/settingzsh/cli.py`
- Test: `tests/test_settingzsh_bootstrap.py`

**Step 1: Write the failing test**

```python
def test_render_bootstrap_block():
    block = render_bootstrap_block()
    assert 'settingZsh bootstrap' in block
    assert 'source "$HOME/.config/settingzsh/init.zsh"' in block


def test_render_init_zsh_loads_managed_fragments_once():
    content = render_init_zsh()
    assert "managed.d" in content
    assert "SETTINGZSH_LOADED" in content
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_bootstrap.py -v`
Expected: FAIL because render functions do not exist

**Step 3: Write minimal implementation**

```python
def render_bootstrap_block() -> str:
    return '\n'.join([
        '# >>> settingZsh bootstrap >>>',
        '[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"',
        '# <<< settingZsh bootstrap <<<',
    ]) + '\n'
```

```python
def render_init_zsh() -> str:
    return '\n'.join([
        '[[ -n "${SETTINGZSH_LOADED:-}" ]] && return 0',
        'export SETTINGZSH_LOADED=1',
        'for file in "$HOME"/.config/settingzsh/managed.d/*.zsh; do',
        '  [ -f "$file" ] && source "$file"',
        'done',
    ]) + '\n'
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_bootstrap.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/shellgen.py lib/settingzsh/bootstrap.py lib/settingzsh/cli.py tests/test_settingzsh_bootstrap.py
git commit -m "重構(shell): 產生 bootstrap 與 managed 載入器"
```

### Task 3: 實作唯讀 doctor 診斷

**Files:**
- Create: `lib/settingzsh/doctor.py`
- Modify: `lib/settingzsh/cli.py`
- Modify: `lib/settingzsh/state.py`
- Test: `tests/test_settingzsh_doctor.py`
- Create: `tests/fixtures/zshrc/legacy_markers.zshrc`
- Create: `tests/fixtures/zshrc/third_party_only.zshrc`

**Step 1: Write the failing test**

```python
def test_doctor_reports_legacy_markers(tmp_path):
    result = run_doctor(target_home=tmp_path, zshrc_fixture="legacy_markers.zshrc")
    assert result.status == "warn"
    assert "legacy_markers" in result.issues
    assert result.modified_files == []
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_doctor.py::test_doctor_reports_legacy_markers -v`
Expected: FAIL because doctor command is not implemented

**Step 3: Write minimal implementation**

```python
def run_doctor(target_home: Path) -> DoctorResult:
    zshrc = target_home / ".zshrc"
    issues = []
    if "settingZsh:managed:" in zshrc.read_text(encoding="utf-8"):
        issues.append("legacy_markers")
    return DoctorResult(status="warn" if issues else "ok", issues=issues, modified_files=[])
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_doctor.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/doctor.py lib/settingzsh/cli.py lib/settingzsh/state.py tests/test_settingzsh_doctor.py tests/fixtures/zshrc/legacy_markers.zshrc tests/fixtures/zshrc/third_party_only.zshrc
git commit -m "重構(doctor): 新增唯讀 shell 健康檢查"
```

### Task 4: 實作 migrate，僅搬移 settingZsh 自己的舊結構

**Files:**
- Create: `lib/settingzsh/migrate.py`
- Modify: `lib/settingzsh/cli.py`
- Modify: `lib/settingzsh/bootstrap.py`
- Test: `tests/test_settingzsh_migrate.py`
- Create: `tests/fixtures/zshrc/mixed_state.zshrc`

**Step 1: Write the failing test**

```python
def test_migrate_rewrites_only_settingzsh_sections(tmp_path):
    result = run_migrate(target_home=tmp_path, zshrc_fixture="mixed_state.zshrc")
    zshrc = (tmp_path / ".zshrc").read_text(encoding="utf-8")
    assert "# >>> settingZsh bootstrap >>>" in zshrc
    assert "settingZsh:managed:" not in zshrc
    assert "Added by Spectra" in zshrc
    assert (tmp_path / ".config/settingzsh/managed.d/10-base.zsh").exists()
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_migrate.py::test_migrate_rewrites_only_settingzsh_sections -v`
Expected: FAIL because migrate logic does not exist

**Step 3: Write minimal implementation**

```python
def run_migrate(target_home: Path) -> MigrateResult:
    # 1. extract managed blocks
    # 2. write managed.d fragments
    # 3. replace legacy markers with bootstrap
    # 4. preserve all non-settingZsh text verbatim
    ...
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_migrate.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/migrate.py lib/settingzsh/cli.py lib/settingzsh/bootstrap.py tests/test_settingzsh_migrate.py tests/fixtures/zshrc/mixed_state.zshrc
git commit -m "重構(migrate): 收斂舊版 markers 為 bootstrap"
```

### Task 5: 加入驗證與回滾保護

**Files:**
- Create: `lib/settingzsh/reconcile.py`
- Modify: `lib/settingzsh/migrate.py`
- Modify: `lib/settingzsh/doctor.py`
- Test: `tests/test_settingzsh_reconcile.py`

**Step 1: Write the failing test**

```python
def test_failed_validation_restores_original_zshrc(tmp_path):
    original = (tmp_path / ".zshrc").read_text(encoding="utf-8")
    result = run_migrate_with_invalid_fragment(tmp_path)
    assert result.status == "rolled_back"
    assert (tmp_path / ".zshrc").read_text(encoding="utf-8") == original
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_reconcile.py::test_failed_validation_restores_original_zshrc -v`
Expected: FAIL because rollback path is missing

**Step 3: Write minimal implementation**

```python
def validate_shell(target_home: Path) -> None:
    subprocess.run(["zsh", "-n", str(target_home / ".zshrc")], check=True)
    subprocess.run(["zsh", "-i", "-c", "exit"], env={**os.environ, "ZDOTDIR": str(target_home)}, check=True)
```

```python
try:
    write_candidate_files(...)
    validate_shell(target_home)
except subprocess.CalledProcessError:
    restore_backup(...)
    return Result(status="rolled_back")
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_reconcile.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/reconcile.py lib/settingzsh/migrate.py lib/settingzsh/doctor.py tests/test_settingzsh_reconcile.py
git commit -m "重構(validate): 加入 shell 驗證與自動回滾"
```

### Task 6: 將 setup/update 改為呼叫 Python CLI

**Files:**
- Modify: `setup.sh`
- Modify: `setup_mac.sh`
- Modify: `setup_linux.sh`
- Modify: `update.sh`
- Modify: `update_mac.sh`
- Modify: `update_linux.sh`
- Test: `tests/test_mac.sh`
- Test: `tests/test_linux.sh`

**Step 1: Write the failing test**

```bash
# tests/test_mac.sh
if grep -q 'cp "$template" "$target"' "$PROJECT_DIR/setup_mac.sh"; then
  fail "仍存在 .zshrc destructive fallback"
fi
```

```bash
# tests/test_linux.sh
if ! grep -q 'uv run .*settingzsh' "$PROJECT_DIR/setup_linux.sh"; then
  fail "尚未改用 Python CLI"
fi
```

**Step 2: Run test to verify it fails**

Run: `bash tests/test_mac.sh`
Expected: FAIL because shell wrapper still contains old merge behavior

**Step 3: Write minimal implementation**

```bash
uv run python -m settingzsh.cli setup
uv run python -m settingzsh.cli update
uv run python -m settingzsh.cli doctor
```

- 移除 `.zshrc` 相關 destructive fallback
- 保留套件安裝邏輯，但 shell 管理改委派給 Python CLI

**Step 4: Run test to verify it passes**

Run: `bash tests/test_mac.sh && bash tests/test_linux.sh`
Expected: PASS with no `.zshrc` merge fallback warnings

**Step 5: Commit**

```bash
git add setup.sh setup_mac.sh setup_linux.sh update.sh update_mac.sh update_linux.sh tests/test_mac.sh tests/test_linux.sh
git commit -m "重構(setup): 以 Python CLI 接管 shell 狀態管理"
```

### Task 7: 更新 README 與操作文件

**Files:**
- Modify: `README.md`
- Modify: `docs/editor-guide.md`
- Modify: `tests/TEST_REPORT.md`

**Step 1: Write the failing test**

```python
def test_readme_mentions_doctor_and_migrate():
    readme = Path("README.md").read_text(encoding="utf-8")
    assert "doctor" in readme
    assert "migrate" in readme
    assert "bootstrap" in readme
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_docs.py::test_readme_mentions_doctor_and_migrate -v`
Expected: FAIL because docs still describe full-file merge as primary model

**Step 3: Write minimal implementation**

```markdown
- `setup`：安裝 managed fragments，不主動重排既有 `.zshrc`
- `doctor`：檢查 bootstrap、舊版 markers、shell 驗證結果
- `migrate`：僅收斂 `settingZsh` 舊版區塊
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_docs.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add README.md docs/editor-guide.md tests/TEST_REPORT.md
git commit -m "文件(setup): 更新 bootstrap 化操作說明"
```

### Task 8: 最終驗證與清理

**Files:**
- Modify: `tests/test_config_merge.py`
- Modify: `lib/config_merge.py`
- Modify: `README.md`

**Step 1: Write the failing test**

```python
def test_config_merge_not_used_for_zshrc_flow():
    readme = Path("README.md").read_text(encoding="utf-8")
    assert "config_merge.py" not in extract_primary_zsh_setup_section(readme)
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_config_merge.py -k zshrc_flow -v`
Expected: FAIL because docs and code still imply `config_merge.py` manages `.zshrc`

**Step 3: Write minimal implementation**

- 將 `config_merge.py` 角色重新收斂為非主流程工具
- 清理 README 中 `.zshrc` 主要流程對 merge engine 的依賴描述
- 補上 deprecation note 或明確限定用途

**Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_config_merge.py tests/test_settingzsh_*.py`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/config_merge.py tests/test_config_merge.py README.md
git commit -m "重構(config): 收斂舊 merge engine 的責任範圍"
```
