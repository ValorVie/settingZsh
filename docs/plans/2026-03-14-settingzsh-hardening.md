# settingZsh 部署、設定與邊界防護 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 為 `settingZsh` 補上多機部署優先的設定層、部署狀態管理、與更完整的 shell 邊界防護。

**Architecture:** 延續現有 bootstrap + `managed.d` + `doctor/migrate/reconcile` 模型，新增 `settings.default.toml`、`settings.local.toml`、`local.d`、`state.json`、artifact cache metadata 與 `repair` 命令。`reconcile` 維持保守，只補本工具自己的 shell 資產；較侵入的修復集中到 `repair`。

**Tech Stack:** Bash、Python 3.10+、uv、pytest、zsh、TOML、JSON

---

### Task 1: 建立設定與 state 模型

**Files:**
- Create: `config/settings.default.toml`
- Create: `lib/settingzsh/config.py`
- Modify: `lib/settingzsh/state.py`
- Test: `tests/test_settingzsh_config.py`

**Step 1: Write the failing test**

```python
def test_load_settings_merges_default_and_local(tmp_path):
    default_path = tmp_path / "settings.default.toml"
    local_path = tmp_path / "settings.local.toml"
    default_path.write_text("[shell]\nenable_currentdir_hook = false\n", encoding="utf-8")
    local_path.write_text("[shell]\nenable_currentdir_hook = true\n", encoding="utf-8")

    settings = load_settings(default_path=default_path, local_path=local_path)

    assert settings.shell.enable_currentdir_hook is True
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_config.py::test_load_settings_merges_default_and_local -v`
Expected: FAIL because `load_settings` does not exist

**Step 3: Write minimal implementation**

```python
@dataclass(slots=True)
class ShellSettings:
    enable_currentdir_hook: bool = False


def load_settings(default_path: Path, local_path: Path | None) -> Settings:
    default_data = tomllib.loads(default_path.read_text(encoding="utf-8"))
    local_data = tomllib.loads(local_path.read_text(encoding="utf-8")) if local_path and local_path.exists() else {}
    merged = deep_merge(default_data, local_data)
    return Settings.from_dict(merged)
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_config.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add config/settings.default.toml lib/settingzsh/config.py lib/settingzsh/state.py tests/test_settingzsh_config.py
git commit -m "feat(config): 新增設定與 state 模型"
```

### Task 2: 載入 local.d 並固定 shell 載入順序

**Files:**
- Modify: `lib/settingzsh/shellgen.py`
- Modify: `lib/settingzsh/cli.py`
- Test: `tests/test_settingzsh_bootstrap.py`
- Test: `tests/test_settingzsh_cli.py`

**Step 1: Write the failing test**

```python
def test_render_init_zsh_loads_local_fragments_after_managed():
    content = render_init_zsh()
    assert 'managed.d/*.zsh' in content
    assert 'local.d/*.zsh' in content
    assert content.index("managed.d") < content.index("local.d")
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_bootstrap.py::test_render_init_zsh_loads_local_fragments_after_managed -v`
Expected: FAIL because `local.d` is not loaded

**Step 3: Write minimal implementation**

```python
def render_init_zsh() -> str:
    return "\n".join([
        '[[ -n "${SETTINGZSH_LOADED:-}" ]] && return 0',
        "export SETTINGZSH_LOADED=1",
        'for file in "$HOME"/.config/settingzsh/managed.d/*.zsh(N); do',
        '  [ -f "$file" ] && source "$file"',
        "done",
        'for file in "$HOME"/.config/settingzsh/local.d/*.zsh(N); do',
        '  [ -f "$file" ] && source "$file"',
        "done",
    ]) + "\n"
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_bootstrap.py tests/test_settingzsh_cli.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/shellgen.py lib/settingzsh/cli.py tests/test_settingzsh_bootstrap.py tests/test_settingzsh_cli.py
git commit -m "feat(shell): 新增 local.d 載入層"
```

### Task 3: 擴充 doctor 為 drift 與邊界檢查

**Files:**
- Modify: `lib/settingzsh/doctor.py`
- Modify: `lib/settingzsh/state.py`
- Test: `tests/test_settingzsh_doctor.py`
- Create: `tests/fixtures/zshrc/duplicate_compinit.zshrc`
- Create: `tests/fixtures/zshrc/precmd_conflict.zshrc`

**Step 1: Write the failing test**

```python
def test_doctor_reports_duplicate_compinit(tmp_path):
    home = prepare_home(tmp_path, "duplicate_compinit.zshrc")
    result = run_doctor(target_home=home)
    assert "duplicate_compinit" in result.issues
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_doctor.py::test_doctor_reports_duplicate_compinit -v`
Expected: FAIL because the finding is not implemented

**Step 3: Write minimal implementation**

```python
if content.count("compinit") > 1:
    issues.append("duplicate_compinit")

if "precmd ()" in content and "precmd_functions+=" in content:
    issues.append("precmd_conflict")
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_doctor.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/doctor.py lib/settingzsh/state.py tests/test_settingzsh_doctor.py tests/fixtures/zshrc/duplicate_compinit.zshrc tests/fixtures/zshrc/precmd_conflict.zshrc
git commit -m "feat(doctor): 擴充 drift 與邊界檢查"
```

### Task 4: 導入 repair 並與 reconcile 分離

**Files:**
- Modify: `lib/settingzsh/cli.py`
- Modify: `lib/settingzsh/reconcile.py`
- Test: `tests/test_settingzsh_reconcile.py`

**Step 1: Write the failing test**

```python
def test_reconcile_does_not_overwrite_existing_managed_fragment(tmp_path):
    ...


def test_repair_can_refresh_managed_fragment(tmp_path):
    ...
    assert refreshed_content == expected_template
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_reconcile.py -k 'reconcile or repair' -v`
Expected: FAIL because `repair` command does not exist

**Step 3: Write minimal implementation**

```python
def run_repair(target_home: Path, *, refresh_managed: bool = True) -> CommandResult:
    write_plan = build_refresh_plan(target_home)
    apply_with_validation(...)
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_reconcile.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/cli.py lib/settingzsh/reconcile.py tests/test_settingzsh_reconcile.py
git commit -m "feat(repair): 分離保守 reconcile 與顯式修復"
```

### Task 5: 補上 non-interactive 部署入口與 state persistence

**Files:**
- Modify: `setup.sh`
- Modify: `setup_mac.sh`
- Modify: `setup_linux.sh`
- Modify: `update.sh`
- Modify: `update_mac.sh`
- Modify: `update_linux.sh`
- Modify: `lib/settingzsh/cli.py`
- Test: `tests/test_mac.sh`
- Test: `tests/test_linux.sh`

**Step 1: Write the failing test**

```bash
if ! grep -q -- '--with-editor' "$PROJECT_DIR/setup_mac.sh"; then
  fail "setup_mac.sh 尚未支援 non-interactive editor 安裝"
fi
```

**Step 2: Run test to verify it fails**

Run: `bash tests/test_mac.sh`
Expected: FAIL because wrapper flags do not exist

**Step 3: Write minimal implementation**

```bash
case "${1:-}" in
  --with-editor) INSTALL_EDITOR=1 ;;
esac
```

```python
def write_state(...):
    state_path.write_text(json.dumps(state))
```

**Step 4: Run test to verify it passes**

Run: `bash tests/test_mac.sh && bash tests/test_linux.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add setup.sh setup_mac.sh setup_linux.sh update.sh update_mac.sh update_linux.sh lib/settingzsh/cli.py tests/test_mac.sh tests/test_linux.sh
git commit -m "feat(setup): 新增 non-interactive 旗標與 state persistence"
```

### Task 6: 導入 artifact cache 與下載 metadata

**Files:**
- Create: `lib/settingzsh/artifacts.py`
- Modify: `setup_mac.sh`
- Modify: `setup_linux.sh`
- Modify: `update_mac.sh`
- Modify: `update_linux.sh`
- Test: `tests/test_settingzsh_artifacts.py`

**Step 1: Write the failing test**

```python
def test_download_artifact_uses_cached_file_when_checksum_matches(tmp_path):
    ...
    assert result.source == "cache"
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_artifacts.py -v`
Expected: FAIL because artifact cache module does not exist

**Step 3: Write minimal implementation**

```python
def ensure_artifact(url: str, cache_path: Path, sha256: str) -> Path:
    if cache_path.exists() and verify_sha256(cache_path, sha256):
        return cache_path
    download(url, cache_path)
    verify_sha256(cache_path, sha256)
    return cache_path
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_artifacts.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/settingzsh/artifacts.py setup_mac.sh setup_linux.sh update_mac.sh update_linux.sh tests/test_settingzsh_artifacts.py
git commit -m "feat(artifacts): 新增下載快取與 metadata"
```

### Task 7: 更新文件與操作指南

**Files:**
- Modify: `README.md`
- Modify: `docs/editor-guide.md`
- Modify: `tests/TEST_REPORT.md`
- Test: `tests/test_settingzsh_docs.py`

**Step 1: Write the failing test**

```python
def test_readme_mentions_local_override_and_repair():
    readme = Path("README.md").read_text(encoding="utf-8")
    assert "settings.local.toml" in readme
    assert "local.d" in readme
    assert "repair" in readme
```

**Step 2: Run test to verify it fails**

Run: `uv run pytest tests/test_settingzsh_docs.py::test_readme_mentions_local_override_and_repair -v`
Expected: FAIL because docs do not mention new model

**Step 3: Write minimal implementation**

```markdown
- repo default: `config/settings.default.toml`
- machine override: `~/.config/settingzsh/settings.local.toml`
- shell code override: `~/.config/settingzsh/local.d/*.zsh`
- `repair`: 顯式修復模式
```

**Step 4: Run test to verify it passes**

Run: `uv run pytest tests/test_settingzsh_docs.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add README.md docs/editor-guide.md tests/TEST_REPORT.md tests/test_settingzsh_docs.py
git commit -m "docs(settingzsh): 更新設定層與 repair 操作說明"
```
