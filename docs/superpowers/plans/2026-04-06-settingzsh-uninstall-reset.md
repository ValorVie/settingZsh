# settingZsh 卸載與安全重置 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增可安全卸載 `settingZsh` 的文件與腳本，移除 source state / baseline 痕跡但不誤刪使用者原有設定，並補上 LXC / `chsh` 的安裝說明。

**Architecture:** 使用 `scripts/uninstall-settingzsh.sh` 作為使用者入口，內部委派到 `lib/settingzsh/uninstall.py`，讓 ownership 判斷、manifest、execute/restore 都能以 Python 做可測試的安全實作。`.zshrc`、PowerShell profile、SSH config 採內容辨識與局部 strip；共享路徑預設只報告不自動刪除。

**Tech Stack:** Bash wrapper, Python stdlib, pytest, shell smoke tests, Markdown docs

---

## File Structure

- Create: `lib/settingzsh/uninstall.py`
  - 核心卸載邏輯、CLI、manifest、dry-run / execute / restore
- Create: `scripts/uninstall-settingzsh.sh`
  - 使用者入口，設定 `PYTHONPATH` 後執行 `python3 -m settingzsh.uninstall`
- Create: `tests/test_settingzsh_uninstall.py`
  - 單元測試：ownership 分類、bootstrap strip、PowerShell bridge 辨識、manifest round-trip
- Create: `tests/chezmoi/test_uninstall_flow.sh`
  - 端到端 smoke：`--dry-run`、`--execute`、`--restore`
- Create: `docs/uninstall-guide.md`
  - 手動刪除 / 還原流程與共享路徑人工確認說明
- Modify: `README.md`
  - 新增卸載與重置章節，補 `exec zsh` 與 `chsh` 的區別
- Modify: `tests/test_settingzsh_docs.py`
  - 驗證 README 與 `docs/uninstall-guide.md` 的文字承諾

---

### Task 1: 建立卸載核心與單元測試

**Files:**
- Create: `lib/settingzsh/uninstall.py`
- Create: `tests/test_settingzsh_uninstall.py`
- Test: `tests/test_settingzsh_uninstall.py`

- [ ] **Step 1: 寫 failing unit tests，定義 ownership 與 rewrite 行為**

```python
from __future__ import annotations

import sys
from pathlib import Path

_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.uninstall import collect_uninstall_plan
from settingzsh.uninstall import is_settingzsh_powershell_bridge
from settingzsh.uninstall import strip_settingzsh_bootstrap


def _action(plan, target: Path):
    for action in plan.actions:
        if action.path == target:
            return action
    raise AssertionError(f"missing action for {target}")


def test_collect_uninstall_plan_marks_owned_and_shared_paths(tmp_path: Path) -> None:
    home = tmp_path / "home"
    (home / ".local" / "share" / "chezmoi").mkdir(parents=True)
    (home / ".config" / "settingzsh").mkdir(parents=True)
    (home / ".fzf").mkdir(parents=True)

    plan = collect_uninstall_plan(home)

    assert _action(plan, home / ".local" / "share" / "chezmoi").kind == "move"
    assert _action(plan, home / ".config" / "settingzsh").kind == "move"
    assert _action(plan, home / ".fzf").kind == "shared"


def test_strip_settingzsh_bootstrap_preserves_user_content() -> None:
    content = (
        "export TEST_VAR=1\n"
        "# >>> settingZsh bootstrap >>>\n"
        "[ -f \"$HOME/.config/settingzsh/init.zsh\" ] && source \"$HOME/.config/settingzsh/init.zsh\"\n"
        "# <<< settingZsh bootstrap <<<\n"
    )

    assert strip_settingzsh_bootstrap(content) == "export TEST_VAR=1\n"


def test_collect_uninstall_plan_removes_pure_bootstrap_file(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()
    zshrc = home / ".zshrc"
    zshrc.write_text(
        "# managed by chezmoi: settingZsh public baseline\n"
        "if [ -f \"$HOME/.config/settingzsh/init.zsh\" ]; then\n"
        "  source \"$HOME/.config/settingzsh/init.zsh\"\n"
        "fi\n",
        encoding="utf-8",
    )

    plan = collect_uninstall_plan(home)

    assert _action(plan, zshrc).kind == "remove-file"


def test_is_settingzsh_powershell_bridge_matches_public_bridge() -> None:
    content = (
        '$baseline = Join-Path $HOME ".config/settingzsh/powershell/public-baseline.ps1"\n'
        'if (Test-Path $baseline) { . $baseline }\n'
    )

    assert is_settingzsh_powershell_bridge(content) is True
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `pytest tests/test_settingzsh_uninstall.py -q`  
Expected: FAIL with `ModuleNotFoundError: No module named 'settingzsh.uninstall'`

- [ ] **Step 3: 寫最小可通過的卸載核心**

```python
from __future__ import annotations

import json
import re
from dataclasses import asdict
from dataclasses import dataclass
from pathlib import Path

from settingzsh.bootstrap import is_bootstrap_file
from settingzsh.bootstrap import strip_bootstrap_content


@dataclass(slots=True)
class UninstallAction:
    kind: str
    path: Path
    detail: str = ""


@dataclass(slots=True)
class UninstallPlan:
    home: Path
    actions: list[UninstallAction]


_PS_BRIDGE_SNIPPETS = (
    ".config/settingzsh/powershell/public-baseline.ps1",
    "public-baseline.ps1",
)


def strip_settingzsh_bootstrap(content: str) -> str:
    return strip_bootstrap_content(content)


def is_settingzsh_powershell_bridge(content: str) -> bool:
    normalized = content.replace("\r\n", "\n")
    return all(snippet in normalized for snippet in _PS_BRIDGE_SNIPPETS)


def collect_uninstall_plan(home: Path) -> UninstallPlan:
    home = home.resolve()
    actions: list[UninstallAction] = []

    for owned in (
        home / ".local" / "share" / "chezmoi",
        home / ".config" / "chezmoi",
        home / ".cache" / "chezmoi",
        home / ".config" / "settingzsh",
        home / ".local" / "share" / "settingzsh",
    ):
        if owned.exists():
            actions.append(UninstallAction(kind="move", path=owned))

    for shared in (
        home / ".fzf",
        home / ".local" / "bin",
        home / ".local" / "share" / "zinit" / "zinit.git",
        home / ".local" / "share" / "fonts" / "MapleMono",
    ):
        if shared.exists():
            actions.append(UninstallAction(kind="shared", path=shared))

    zshrc = home / ".zshrc"
    if zshrc.exists():
        content = zshrc.read_text(encoding="utf-8")
        if is_bootstrap_file(content):
            actions.append(UninstallAction(kind="remove-file", path=zshrc, detail="pure-bootstrap"))
        else:
            stripped = strip_settingzsh_bootstrap(content)
            if stripped != content:
                kind = "remove-file" if stripped == "" else "rewrite-file"
                actions.append(UninstallAction(kind=kind, path=zshrc, detail="strip-bootstrap"))

    return UninstallPlan(home=home, actions=actions)


def plan_to_json(plan: UninstallPlan) -> str:
    payload = {
        "home": str(plan.home),
        "actions": [
            {"kind": action.kind, "path": str(action.path), "detail": action.detail}
            for action in plan.actions
        ],
    }
    return json.dumps(payload, indent=2, sort_keys=True)
```

- [ ] **Step 4: 跑測試確認通過**

Run: `pytest tests/test_settingzsh_uninstall.py -q`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/settingzsh/uninstall.py tests/test_settingzsh_uninstall.py
git commit -m "feat(uninstall): 建立安全卸載核心"
```

---

### Task 2: 補上 execute / restore 與腳本入口

**Files:**
- Modify: `lib/settingzsh/uninstall.py`
- Create: `scripts/uninstall-settingzsh.sh`
- Create: `tests/chezmoi/test_uninstall_flow.sh`
- Test: `tests/test_settingzsh_uninstall.py`
- Test: `tests/chezmoi/test_uninstall_flow.sh`

- [ ] **Step 1: 寫 failing shell smoke test，定義 dry-run / execute / restore**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_root="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

home="$tmp_root/home"
backup_root="$tmp_root/backups"
mkdir -p "$home/.local/share/chezmoi" "$home/.config/settingzsh" "$backup_root"
cat > "$home/.zshrc" <<'EOF'
export TEST_VAR=1
# >>> settingZsh bootstrap >>>
[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"
# <<< settingZsh bootstrap <<<
EOF

dry_run_output="$("$ROOT_DIR/scripts/uninstall-settingzsh.sh" --home "$home" --backup-root "$backup_root" --dry-run)"
printf '%s\n' "$dry_run_output" | rg -F ".local/share/chezmoi"
[ -d "$home/.local/share/chezmoi" ]

"$ROOT_DIR/scripts/uninstall-settingzsh.sh" --home "$home" --backup-root "$backup_root" --execute
[ ! -d "$home/.local/share/chezmoi" ]
printf '%s\n' "$(cat "$home/.zshrc")" | rg -F "export TEST_VAR=1"
if rg -Fq "settingZsh bootstrap" "$home/.zshrc"; then
  echo "bootstrap block should be removed"
  exit 1
fi

backup_id="$(basename "$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d | head -n 1)")"
"$ROOT_DIR/scripts/uninstall-settingzsh.sh" --home "$home" --backup-root "$backup_root" --restore "$backup_id"
[ -d "$home/.local/share/chezmoi" ]
printf '%s\n' "$(cat "$home/.zshrc")" | rg -F "settingZsh bootstrap"

echo "uninstall flow: ok"
```

- [ ] **Step 2: 跑 smoke test 確認失敗**

Run: `bash tests/chezmoi/test_uninstall_flow.sh`  
Expected: FAIL with `No such file or directory` for `scripts/uninstall-settingzsh.sh`

- [ ] **Step 3: 實作 CLI、backup/manifest、wrapper**

```python
def execute_uninstall(plan: UninstallPlan, *, backup_root: Path) -> Path:
    backup_dir = backup_root / _timestamp()
    owned_dir = backup_dir / "owned"
    rewritten_dir = backup_dir / "rewritten"
    owned_dir.mkdir(parents=True, exist_ok=True)
    rewritten_dir.mkdir(parents=True, exist_ok=True)

    manifest: dict[str, object] = {
        "home": str(plan.home),
        "owned": [],
        "rewritten": [],
        "shared": [],
    }

    for action in plan.actions:
        if action.kind == "move":
            dest = owned_dir / _relative_to_home(plan.home, action.path)
            dest.parent.mkdir(parents=True, exist_ok=True)
            action.path.rename(dest)
            manifest["owned"].append({"path": str(action.path), "backup": str(dest)})
        elif action.kind in {"remove-file", "rewrite-file"}:
            original = action.path.read_text(encoding="utf-8")
            backup = rewritten_dir / _relative_to_home(plan.home, action.path)
            backup.parent.mkdir(parents=True, exist_ok=True)
            backup.write_text(original, encoding="utf-8")
            manifest["rewritten"].append(
                {"path": str(action.path), "backup": str(backup), "kind": action.kind, "detail": action.detail}
            )
            if action.detail == "strip-bootstrap":
                stripped = strip_settingzsh_bootstrap(original)
                if stripped == "":
                    action.path.unlink()
                else:
                    action.path.write_text(stripped, encoding="utf-8")
            else:
                action.path.unlink()
        elif action.kind == "shared":
            manifest["shared"].append(str(action.path))

    (backup_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return backup_dir


def restore_uninstall(*, home: Path, backup_root: Path, backup_id: str) -> None:
    backup_dir = backup_root / backup_id
    manifest = json.loads((backup_dir / "manifest.json").read_text(encoding="utf-8"))
    for entry in manifest["owned"]:
        source = Path(entry["backup"])
        target = Path(entry["path"])
        target.parent.mkdir(parents=True, exist_ok=True)
        source.rename(target)
    for entry in manifest["rewritten"]:
        backup = Path(entry["backup"])
        target = Path(entry["path"])
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(backup.read_text(encoding="utf-8"), encoding="utf-8")
```

```python
def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="settingzsh-uninstall")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--execute", action="store_true")
    mode.add_argument("--restore")
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument(
        "--backup-root",
        type=Path,
        default=Path.home() / ".local" / "share" / "settingzsh-uninstall-backups",
    )
    args = parser.parse_args(argv)

    if args.restore:
        restore_uninstall(home=args.home, backup_root=args.backup_root, backup_id=args.restore)
        return 0

    plan = collect_uninstall_plan(args.home)
    if args.dry_run:
        print(render_plan_report(plan))
        return 0

    backup_dir = execute_uninstall(plan, backup_root=args.backup_root)
    print(f"Backup created at: {backup_dir}")
    return 0
```

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export PYTHONPATH="$ROOT_DIR/lib${PYTHONPATH:+:$PYTHONPATH}"

exec python3 -m settingzsh.uninstall "$@"
```

- [ ] **Step 4: 跑 unit + smoke tests 確認通過**

Run: `pytest tests/test_settingzsh_uninstall.py -q`  
Expected: PASS

Run: `bash tests/chezmoi/test_uninstall_flow.sh`  
Expected: `uninstall flow: ok`

- [ ] **Step 5: Commit**

```bash
git add lib/settingzsh/uninstall.py scripts/uninstall-settingzsh.sh tests/chezmoi/test_uninstall_flow.sh tests/test_settingzsh_uninstall.py
git commit -m "feat(uninstall): 新增 execute 與 restore 流程"
```

---

### Task 3: 補文件、README 與 docs tests

**Files:**
- Create: `docs/uninstall-guide.md`
- Modify: `README.md`
- Modify: `tests/test_settingzsh_docs.py`
- Test: `tests/test_settingzsh_docs.py`

- [ ] **Step 1: 寫 failing docs tests，定義卸載與 `chsh` 說明**

```python
def test_readme_mentions_uninstall_reset_and_login_shell_guidance() -> None:
    readme = (_PROJECT_ROOT / "README.md").read_text(encoding="utf-8")

    assert "docs/uninstall-guide.md" in readme
    assert "~/.local/share/chezmoi" in readme
    assert "exec zsh" in readme
    assert 'chsh -s /bin/zsh "$(whoami)"' in readme


def test_uninstall_guide_documents_dry_run_execute_restore() -> None:
    guide = (_PROJECT_ROOT / "docs" / "uninstall-guide.md").read_text(encoding="utf-8")

    assert "--dry-run" in guide
    assert "--execute" in guide
    assert "--restore" in guide
    assert "共享路徑" in guide
    assert "~/.local/share/chezmoi" in guide
    assert 'chsh -s /bin/zsh "$(whoami)"' in guide
```

- [ ] **Step 2: 跑 docs tests 確認失敗**

Run: `pytest tests/test_settingzsh_docs.py -q`  
Expected: FAIL because `docs/uninstall-guide.md` does not exist yet and README 尚未提到 uninstall / `chsh`

- [ ] **Step 3: 寫文件與 README 更新**

```md
# settingZsh 卸載指南

## 什麼情況需要卸載 / 重置

- source state 疑似卡在舊版
- 想完全移除 public baseline
- 想保留原有 shell / SSH 設定，但移除 `settingZsh` 痕跡

## 標準流程

1. `scripts/uninstall-settingzsh.sh --dry-run`
2. 檢查 owned / rewritten / shared 清單
3. `scripts/uninstall-settingzsh.sh --execute`
4. 若要還原：`scripts/uninstall-settingzsh.sh --restore <backup-id>`

## 共享路徑

以下路徑預設不自動刪除，只列入報告：

- `~/.local/bin`
- `~/.fzf`
- `~/.local/share/zinit/zinit.git`
- `~/.local/share/fonts/MapleMono`

## LXC / login shell

- `exec zsh` 只切換目前 session
- 若要把帳號預設 shell 改成 zsh，請手動執行：

```bash
chsh -s /bin/zsh "$(whoami)"
```
```

```md
## 卸載與重置

若你懷疑 `~/.local/share/chezmoi` 還留著舊 source state，先不要直接重跑安裝。請先看 [docs/uninstall-guide.md](./docs/uninstall-guide.md)。

補充：

- `exec zsh` 只影響目前 shell session
- 若你要把帳號預設 shell 改成 zsh，手動執行：

```bash
chsh -s /bin/zsh "$(whoami)"
```
```

- [ ] **Step 4: 跑 docs tests 確認通過**

Run: `pytest tests/test_settingzsh_docs.py -q`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add README.md docs/uninstall-guide.md tests/test_settingzsh_docs.py
git commit -m "docs(uninstall): 補上安全重置與 login shell 說明"
```

---

### Task 4: 全量驗證與收尾

**Files:**
- Modify: `lib/settingzsh/uninstall.py` (如驗證後需微調)
- Modify: `scripts/uninstall-settingzsh.sh` (如驗證後需微調)
- Modify: `docs/uninstall-guide.md` (如驗證後需微調)
- Test: `tests/test_settingzsh_uninstall.py`
- Test: `tests/chezmoi/test_uninstall_flow.sh`
- Test: `tests/test_settingzsh_docs.py`

- [ ] **Step 1: 跑完整驗證**

Run: `pytest tests/test_settingzsh_uninstall.py tests/test_settingzsh_docs.py -q`  
Expected: PASS

Run: `bash tests/chezmoi/test_uninstall_flow.sh`  
Expected: `uninstall flow: ok`

- [ ] **Step 2: 檢查腳本 help 與 dry-run 輸出**

Run: `scripts/uninstall-settingzsh.sh --help`  
Expected: 顯示 `--dry-run`、`--execute`、`--restore`

Run: `scripts/uninstall-settingzsh.sh --home /tmp/nonexistent --dry-run`  
Expected: 輸出空計畫或 no-op，不應刪除任何路徑

- [ ] **Step 3: 最終 commit**

```bash
git add lib/settingzsh/uninstall.py scripts/uninstall-settingzsh.sh docs/uninstall-guide.md README.md tests/test_settingzsh_uninstall.py tests/chezmoi/test_uninstall_flow.sh tests/test_settingzsh_docs.py
git commit -m "feat(uninstall): 新增安全移除與還原流程"
```

---

## Self-Review

- **Spec coverage:** 已覆蓋 spec 的三個主需求：ownership-based uninstall、手動文件、LXC / `chsh` 說明。
- **Placeholder scan:** 無 `TODO`、`TBD`、`implement later`；每個 code step 都有實際檔案與命令。
- **Type consistency:** `collect_uninstall_plan`、`execute_uninstall`、`restore_uninstall`、`scripts/uninstall-settingzsh.sh` 在所有任務中名稱一致。

