# settingZsh Single Source Home and Bootstrap Utils Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓 `home/` 成為唯一 baseline source，移除 `templates/` 與 `shellgen.py` 的正式來源角色，並把 `bootstrap.py` 收斂成純 `.zshrc` 區塊處理工具。

**Architecture:** `lib/settingzsh` 不再生成 `init.zsh` 或 managed fragments。`bootstrap.py` 只保留 marker、strip、dedupe 等 parsing/normalization 行為。任何 baseline 文本都只存在於 `home/`，不再保留 `templates/` 平行內容。

**Tech Stack:** Python stdlib, pytest, chezmoi source state, shell smoke tests

---

### Task 1: 用測試鎖住「不再從 Python 生成 baseline」的目標

**Files:**
- Modify: `tests/test_settingzsh_bootstrap.py`
- Create: `tests/test_settingzsh_source_of_truth.py`
- Test: `tests/test_settingzsh_bootstrap.py`
- Test: `tests/test_settingzsh_source_of_truth.py`

- [ ] **Step 1: Write the failing tests**

```python
# tests/test_settingzsh_bootstrap.py
from settingzsh import bootstrap


def test_bootstrap_module_only_exposes_zshrc_block_utilities() -> None:
    assert hasattr(bootstrap, "ensure_single_bootstrap_block")
    assert hasattr(bootstrap, "strip_bootstrap_content")
    assert not hasattr(bootstrap, "render_init_zsh")
    assert not hasattr(bootstrap, "render_managed_fragments")
```

```python
# tests/test_settingzsh_source_of_truth.py
from __future__ import annotations

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_legacy_shellgen_module_is_removed() -> None:
    assert not (PROJECT_ROOT / "lib" / "settingzsh" / "shellgen.py").exists()


def test_legacy_template_directory_is_removed() -> None:
    assert not (PROJECT_ROOT / "templates").exists()
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uv run pytest -q tests/test_settingzsh_bootstrap.py tests/test_settingzsh_source_of_truth.py`
Expected: FAIL because `bootstrap.py` still exports render helpers and `shellgen.py` / `templates/` still exist.

- [ ] **Step 3: Simplify bootstrap utilities and delete legacy source files**

```python
# lib/settingzsh/bootstrap.py
from __future__ import annotations

import re

BOOTSTRAP_BEGIN = "# >>> settingZsh bootstrap >>>"
BOOTSTRAP_END = "# <<< settingZsh bootstrap <<<"
_BOOTSTRAP_BLOCK_RE = re.compile(
    rf"(?ms)(?:\n)?{re.escape(BOOTSTRAP_BEGIN)}\n.*?{re.escape(BOOTSTRAP_END)}\n?"
)


def render_bootstrap_block() -> str:
    return (
        "# >>> settingZsh bootstrap >>>\n"
        "[ -f \"$HOME/.config/settingzsh/init.zsh\" ] && source \"$HOME/.config/settingzsh/init.zsh\"\n"
        "# <<< settingZsh bootstrap <<<\n"
    )


def render_bootstrap_file() -> str:
    return (
        "# managed by chezmoi: settingZsh public baseline\n"
        "if [ -f \"$HOME/.config/settingzsh/init.zsh\" ]; then\n"
        "  source \"$HOME/.config/settingzsh/init.zsh\"\n"
        "fi\n"
    )


def strip_bootstrap_content(content: str) -> str:
    if content.strip() == render_bootstrap_file().strip():
        return ""
    stripped = _BOOTSTRAP_BLOCK_RE.sub("", content)
    return stripped if not stripped or stripped.endswith("\n") else f"{stripped}\n"


def ensure_single_bootstrap_block(content: str) -> str:
    if not content.strip() or content.strip() == render_bootstrap_file().strip():
        return render_bootstrap_file()
    stripped = strip_bootstrap_content(content)
    if not stripped.strip():
        return render_bootstrap_block()
    return stripped + render_bootstrap_block()
```

```bash
# files to delete
rm lib/settingzsh/shellgen.py
rm -r templates
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uv run pytest -q tests/test_settingzsh_bootstrap.py tests/test_settingzsh_source_of_truth.py`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/settingzsh/bootstrap.py tests/test_settingzsh_bootstrap.py tests/test_settingzsh_source_of_truth.py
git rm lib/settingzsh/shellgen.py
git rm -r templates
git commit -m "refactor(source): 移除 Python baseline 生成來源"
```

### Task 2: 清理仍依賴 Python renderer 的測試與遺留引用

**Files:**
- Modify: `tests/test_settingzsh_cli.py`
- Modify: `tests/test_settingzsh_migrate.py`
- Modify: `lib/settingzsh/legacy_import.py`
- Test: `tests/test_settingzsh_cli.py`
- Test: `tests/test_settingzsh_migrate.py`
- Test: `tests/test_settingzsh_legacy_import.py`

- [ ] **Step 1: Write the failing tests**

```python
# tests/test_settingzsh_cli.py
def test_cli_tests_do_not_expect_python_generated_managed_fragments(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    assert not (home / ".config" / "settingzsh" / "managed.d" / "10-base.zsh").exists()
```

```python
# tests/test_settingzsh_migrate.py
def test_migrate_only_writes_legacy_user_fragment_when_requested(tmp_path: Path) -> None:
    home = _prepare_home_with_fixture(tmp_path, "mixed_state.zshrc")
    result = run_migrate(target_home=home)
    assert result.status in {"deprecated", "no-op"}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uv run pytest -q tests/test_settingzsh_cli.py tests/test_settingzsh_migrate.py tests/test_settingzsh_legacy_import.py`
Expected: FAIL because the old tests still assume Python writes managed fragments or migrate path remains active.

- [ ] **Step 3: Update tests and keep legacy-import focused on bootstrap stripping only**

```python
# lib/settingzsh/legacy_import.py
from __future__ import annotations

from pathlib import Path

from settingzsh.bootstrap import strip_bootstrap_content
from settingzsh.state import LegacyImportResult


def run_legacy_import(target_home: Path, *, draft: bool = True) -> LegacyImportResult:
    zshrc_path = target_home / ".zshrc"
    if not zshrc_path.exists():
        return LegacyImportResult(status="no-op")

    content = strip_bootstrap_content(zshrc_path.read_text(encoding="utf-8"))
    if not content.strip():
        return LegacyImportResult(status="no-op")

    local_dir = target_home / ".config" / "settingzsh" / "local.d"
    local_dir.mkdir(parents=True, exist_ok=True)
    filename = "90-legacy-import.zsh.draft" if draft else "90-legacy-import.zsh"
    target = local_dir / filename
    target.write_text(content if content.endswith("\n") else f"{content}\n", encoding="utf-8")
    return LegacyImportResult(status="drafted" if draft else "imported", modified_files=[str(target)])
```

```python
# tests/test_settingzsh_migrate.py
def test_migrate_module_is_legacy_only_and_not_used_by_main_flow() -> None:
    from pathlib import Path
    assert (Path(__file__).resolve().parent.parent / "lib" / "settingzsh" / "migrate.py").exists()
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uv run pytest -q tests/test_settingzsh_cli.py tests/test_settingzsh_migrate.py tests/test_settingzsh_legacy_import.py`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/settingzsh/legacy_import.py tests/test_settingzsh_cli.py tests/test_settingzsh_migrate.py tests/test_settingzsh_legacy_import.py
git commit -m "test(source): 對齊單一 baseline 來源模型"
```
