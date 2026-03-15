from __future__ import annotations

import subprocess
import re
from pathlib import Path
from typing import Callable

from settingzsh.preflight import inspect_zshrc_content
from settingzsh.reconcile import inspect_shell_validation
from settingzsh.state import DoctorResult
from settingzsh.state import ShellValidationResult

_COMPIINIT_RE = re.compile(r"\bcompinit\b")
_PRECMD_RE = re.compile(r"^\s*(?:function\s+)?precmd\s*\(", re.MULTILINE)


def run_doctor(
    target_home: Path,
    *,
    validator: Callable[[Path], ShellValidationResult] | None = None,
) -> DoctorResult:
    """Run read-only doctor checks for legacy settingZsh markers."""
    zshrc_path = target_home / ".zshrc"
    issues: list[str] = []

    content = ""
    if zshrc_path.exists():
        content = zshrc_path.read_text(encoding="utf-8")

    if "settingZsh:managed:" in content:
        issues.append("legacy_markers")

    details = inspect_zshrc_content(content)
    if len(_COMPIINIT_RE.findall(content)) > 1:
        issues.append("duplicate_compinit")
    if _PRECMD_RE.search(content) and "precmd_functions" in content:
        issues.append("precmd_override")
    if content.count("brew shellenv") > 1:
        issues.append("duplicate_brew_shellenv")
    if details["secrets"]:
        issues.append("secret_smells")

    runner = validator or inspect_shell_validation
    try:
        validation = runner(target_home)
    except (subprocess.CalledProcessError, OSError, RuntimeError):
        issues.append("shell_validation_failed")
    else:
        issues.extend(validation.issues)

    status = "warn" if issues else "ok"
    return DoctorResult(status=status, issues=issues, modified_files=[])
