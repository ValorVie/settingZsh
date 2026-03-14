from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Callable

from settingzsh.reconcile import validate_zsh_syntax
from settingzsh.state import DoctorResult


def run_doctor(
    target_home: Path,
    *,
    validator: Callable[[Path], None] | None = None,
) -> DoctorResult:
    """Run read-only doctor checks for legacy settingZsh markers."""
    zshrc_path = target_home / ".zshrc"
    issues: list[str] = []

    content = ""
    if zshrc_path.exists():
        content = zshrc_path.read_text(encoding="utf-8")

    if "settingZsh:managed:" in content:
        issues.append("legacy_markers")

    runner = validator or validate_zsh_syntax
    try:
        runner(target_home)
    except (subprocess.CalledProcessError, OSError, RuntimeError):
        issues.append("shell_validation_failed")

    status = "warn" if issues else "ok"
    return DoctorResult(status=status, issues=issues, modified_files=[])
