# settingZsh Docs and Acceptance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓文件敘事、測試分類與最終驗收全面對齊新的單核心架構，並完成整體 acceptance verification。

**Architecture:** README 與 architecture 文件必須只描述一條正式 baseline 寫檔路徑：`chezmoi`。`legacy CLI` 的角色只剩 guardrails。測試改驗證 nested schema、artifact map、guardrail 行為與 fresh-install smoke，不再替舊寫檔路徑背書。

**Tech Stack:** Markdown docs, pytest, shell smoke tests, git

---

### Task 1: 更新文件敘事，讓 docs 與架構一致

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/architecture-diagram.md`
- Modify: `docs/adoption-guide.md`
- Modify: `docs/fresh-install-inventory.md`
- Modify: `docs/editor-guide.md`
- Modify: `tests/test_settingzsh_docs.py`
- Test: `tests/test_settingzsh_docs.py`

- [ ] **Step 1: Write the failing docs tests**

```python
def test_readme_no_longer_treats_migrate_and_reconcile_as_normal_update_path() -> None:
    readme = (_PROJECT_ROOT / "README.md").read_text(encoding="utf-8")

    assert "chezmoi update" in readme
    assert "reconcile is retired" in readme
    assert "migrate is retired" in readme


def test_architecture_doc_describes_guardrails_only_legacy_cli() -> None:
    architecture = (_PROJECT_ROOT / "docs" / "architecture.md").read_text(
        encoding="utf-8"
    )

    assert "legacy CLI" in architecture
    assert "只做 guardrails" in architecture
    assert "唯一 baseline 寫入引擎" in architecture
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_settingzsh_docs.py`
Expected: FAIL because current docs still present `migrate` / `reconcile` as living flows.

- [ ] **Step 3: Update docs to the single-core architecture**

```markdown
# README.md
- 新安裝與 baseline 更新只使用 `chezmoi`
- `preflight` / `adopt` / `doctor` / `legacy-import` 是 guardrails
- `setup` / `update` / `reconcile` / `migrate` 屬於 retired CLI write paths
```

```markdown
# docs/architecture.md
- `chezmoi` 是唯一 baseline 寫入引擎
- `home/` 是唯一 baseline source of truth
- `lib/settingzsh` 只做分析、報告、遷移協助
```

```markdown
# docs/adoption-guide.md
1. `chezmoi init`
2. `preflight`
3. `adopt`（必要時）
4. `chezmoi apply`
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_settingzsh_docs.py`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add README.md docs/architecture.md docs/architecture-diagram.md docs/adoption-guide.md docs/fresh-install-inventory.md docs/editor-guide.md tests/test_settingzsh_docs.py
git commit -m "docs(architecture): 對齊單核心 chezmoi 架構"
```

### Task 2: 補齊 acceptance tests 並跑完整驗證

**Files:**
- Create: `tests/chezmoi/test_consolidation_acceptance.sh`
- Modify: `tests/chezmoi/test_linux_fallback.sh`
- Modify: `tests/test_settingzsh_cli.py`
- Test: `tests/chezmoi/test_consolidation_acceptance.sh`
- Test: `tests/chezmoi/test_apply_smoke.sh`
- Test: `tests/chezmoi/test_fonts_feature_gating.sh`
- Test: `tests/chezmoi/test_linux_fallback.sh`
- Test: `tests/chezmoi/test_platform_script_gating.sh`
- Test: `tests/chezmoi/test_scripts_presence.sh`
- Test: `tests/chezmoi/test_ssh_overlay.sh`
- Test: `tests/test_settingzsh_bootstrap.py`
- Test: `tests/test_settingzsh_cli.py`
- Test: `tests/test_settingzsh_doctor.py`
- Test: `tests/test_settingzsh_docs.py`

- [ ] **Step 1: Write the failing acceptance test**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

test ! -e templates
test ! -f lib/settingzsh/shellgen.py
rg -q "\[data.features\]" home/.chezmoi.toml.tmpl
rg -q 'get \(get \. "features"\) "editor"' home/run_onchange_after_30-install-editor.sh.tmpl
rg -q 'get \(get \. "overlay"\) "repo"' home/run_onchange_after_40-install-private-ssh.sh.tmpl
rg -q "deprecated" lib/settingzsh/cli.py

echo "consolidation acceptance: ok"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/chezmoi/test_consolidation_acceptance.sh`
Expected: FAIL until all previous plans are implemented.

- [ ] **Step 3: Add the acceptance test and run the full verification set**

```bash
bash tests/chezmoi/test_consolidation_acceptance.sh
bash tests/chezmoi/test_apply_smoke.sh
bash tests/chezmoi/test_fonts_feature_gating.sh
bash tests/chezmoi/test_linux_fallback.sh
bash tests/chezmoi/test_platform_script_gating.sh
bash tests/chezmoi/test_scripts_presence.sh
bash tests/chezmoi/test_ssh_overlay.sh
uv run pytest -q tests/test_settingzsh_bootstrap.py tests/test_settingzsh_cli.py tests/test_settingzsh_doctor.py tests/test_settingzsh_docs.py
```

- [ ] **Step 4: Verify the full suite passes**

Expected:
- shell tests print `ok`
- pytest exits `0`
- no command reports legacy template or top-level flag regressions

- [ ] **Step 5: Commit**

```bash
git add tests/chezmoi/test_consolidation_acceptance.sh tests/chezmoi/test_linux_fallback.sh tests/test_settingzsh_cli.py
git commit -m "test(acceptance): 補齊架構收斂驗收"
```
