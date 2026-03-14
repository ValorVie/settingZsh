from __future__ import annotations

from pathlib import Path

from settingzsh.state import DoctorResult


def run_doctor(target_home: Path) -> DoctorResult:
    """Run read-only doctor checks for legacy settingZsh markers."""
    zshrc_path = target_home / ".zshrc"
    issues: list[str] = []

    content = ""
    if zshrc_path.exists():
        content = zshrc_path.read_text(encoding="utf-8")

    if "settingZsh:managed:" in content:
        issues.append("legacy_markers")

    status = "warn" if issues else "ok"
    return DoctorResult(status=status, issues=issues, modified_files=[])
