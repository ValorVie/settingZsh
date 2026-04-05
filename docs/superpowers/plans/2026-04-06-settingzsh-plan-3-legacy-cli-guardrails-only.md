# settingZsh Legacy CLI Guardrails Only Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 收縮 `lib/settingzsh/cli.py` 到 guardrails-only 模型，讓 `setup` / `update` / `reconcile` / `migrate` 不再是 baseline 寫檔入口。

**Architecture:** `preflight`、`adopt`、`doctor`、`legacy-import` 繼續保留。舊寫檔命令改成 deprecation shims：輸出明確指引，回傳非成功狀態，且不得修改檔案。相關寫檔 helpers 與其測試從主流程移除。

**Tech Stack:** Python stdlib, argparse, pytest

---

### Task 1: 用測試鎖住 CLI deprecation shim 行為

**Files:**
- Modify: `tests/test_settingzsh_cli.py`
- Test: `tests/test_settingzsh_cli.py`

- [ ] **Step 1: Write the failing test**

```python
def test_deprecated_setup_prints_chezmoi_guidance_and_does_not_write(
    tmp_path: Path, capsys
) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)

    exit_code = main(["setup", "--home", str(home)])
    output = capsys.readouterr().out

    assert exit_code == 1
    assert "Use `chezmoi init --apply` for fresh install." in output
    assert not (home / ".config" / "settingzsh").exists()


def test_guardrail_commands_still_exist() -> None:
    parser = build_parser()
    commands = _extract_subcommands(parser)
    assert {"preflight", "adopt", "doctor", "legacy-import"} <= commands
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_cli.py`
Expected: FAIL because `setup` still writes through `run_reconcile`.

- [ ] **Step 3: Implement deprecation shims in CLI**

```python
# lib/settingzsh/cli.py
def _deprecated_write_command(command: str) -> int:
    messages = {
        "setup": "Use `chezmoi init --apply` for fresh install.",
        "update": "Use `chezmoi update` to refresh the baseline.",
        "reconcile": "Use `chezmoi apply` or `chezmoi diff`; reconcile is retired.",
        "migrate": "Use `preflight`, `adopt`, or `legacy-import`; migrate is retired.",
    }
    print(f"[settingzsh] {command} is deprecated. {messages[command]}")
    return 1


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command in {"setup", "update", "reconcile", "migrate"}:
        return _deprecated_write_command(args.command)
    if args.command == "doctor":
        result = run_doctor(target_home=args.home)
        return 0 if result.status == "ok" else 1
    if args.command == "preflight":
        result = run_preflight(target_home=args.home)
        return 0 if result.status == "safe" else 1
    if args.command == "adopt":
        result = run_adopt(target_home=args.home)
        return 0 if result.status in {"reported", "no-op"} else 1
    if args.command == "legacy-import":
        result = run_legacy_import(target_home=args.home, draft=True)
        return 0 if result.status in {"drafted", "no-op"} else 1
    return 0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_cli.py`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/settingzsh/cli.py tests/test_settingzsh_cli.py
git commit -m "refactor(cli): 將寫檔命令降級為提示 shim"
```

### Task 2: 移除不再需要的 CLI 寫檔測試與 helper 路徑

**Files:**
- Modify: `tests/test_settingzsh_bootstrap.py`
- Modify: `tests/test_settingzsh_migrate.py`
- Modify: `lib/settingzsh/migrate.py`
- Modify: `lib/settingzsh/reconcile.py`
- Test: `tests/test_settingzsh_bootstrap.py`
- Test: `tests/test_settingzsh_migrate.py`

- [ ] **Step 1: Write the failing tests**

```python
# tests/test_settingzsh_bootstrap.py
def test_main_setup_command_is_no_longer_a_success_path(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    assert main(["setup", "--home", str(home)]) == 1
```

```python
# tests/test_settingzsh_migrate.py
def test_migrate_reports_deprecated_without_touching_files(tmp_path: Path) -> None:
    home = _prepare_home_with_fixture(tmp_path, "mixed_state.zshrc")
    before = (home / ".zshrc").read_text(encoding="utf-8")

    result = run_migrate(target_home=home)

    assert result.status == "deprecated"
    assert (home / ".zshrc").read_text(encoding="utf-8") == before
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_bootstrap.py tests/test_settingzsh_migrate.py`
Expected: FAIL because `setup` still counted as success in tests and `run_migrate` still writes files.

- [ ] **Step 3: Collapse migrate/reconcile into deprecated no-op shims**

```python
# lib/settingzsh/migrate.py
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path


@dataclass(slots=True)
class MigrateResult:
    status: str
    managed_sections: list[str] = field(default_factory=list)
    modified_files: list[str] = field(default_factory=list)


def run_migrate(target_home: Path, *, validator=None) -> MigrateResult:
    return MigrateResult(status="deprecated", managed_sections=[], modified_files=[])
```

```python
# lib/settingzsh/reconcile.py
from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from settingzsh.state import ShellValidationResult

# keep only snapshot + validation helpers; remove write-plan logic entirely
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_bootstrap.py tests/test_settingzsh_migrate.py`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/settingzsh/migrate.py lib/settingzsh/reconcile.py tests/test_settingzsh_bootstrap.py tests/test_settingzsh_migrate.py
git commit -m "refactor(legacy): 移除 CLI baseline 寫檔路徑"
```
