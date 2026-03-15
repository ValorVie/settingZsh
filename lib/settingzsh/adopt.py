from __future__ import annotations

from datetime import datetime
from pathlib import Path

from settingzsh.preflight import run_preflight
from settingzsh.state import AdoptResult


def _timestamp() -> str:
    return datetime.now().strftime("%Y%m%d%H%M%S")


def _build_report(target_home: Path, preflight_status: str, issues: list[str], details: dict[str, list[str]]) -> str:
    lines = [
        "# settingZsh adopt report",
        "",
        f"- home: `{target_home}`",
        f"- preflight: `{preflight_status}`",
        f"- issues: `{', '.join(issues) if issues else 'none'}`",
        "",
    ]
    for key in ("shell_ecosystem", "hooks", "integrations", "secrets"):
        values = details.get(key, [])
        lines.append(f"## {key}")
        if values:
            lines.extend(f"- {value}" for value in values)
        else:
            lines.append("- none")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def run_adopt(target_home: Path) -> AdoptResult:
    zshrc_path = target_home / ".zshrc"
    if not zshrc_path.exists():
        return AdoptResult(status="no-op")

    stamp = _timestamp()
    backup_path = target_home / f".zshrc.bak.{stamp}"
    report_dir = target_home / ".config" / "settingzsh" / "reports"
    report_path = report_dir / f"adopt-report-{stamp}.md"
    report_dir.mkdir(parents=True, exist_ok=True)

    content = zshrc_path.read_text(encoding="utf-8")
    backup_path.write_text(content, encoding="utf-8")

    preflight = run_preflight(target_home=target_home)
    report_path.write_text(
        _build_report(
            target_home=target_home,
            preflight_status=preflight.status,
            issues=preflight.issues,
            details=preflight.details,
        ),
        encoding="utf-8",
    )
    return AdoptResult(
        status="reported",
        issues=preflight.issues,
        modified_files=[str(backup_path), str(report_path)],
    )
