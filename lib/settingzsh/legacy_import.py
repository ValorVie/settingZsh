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
