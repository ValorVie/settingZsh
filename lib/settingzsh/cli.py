from __future__ import annotations

import argparse
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

from settingzsh.bootstrap import (
    has_bootstrap_block,
    render_bootstrap_block,
    render_init_zsh,
    render_managed_fragments,
)
from settingzsh.doctor import run_doctor
from settingzsh.migrate import run_migrate
from settingzsh.reconcile import capture_file_snapshots, restore_file_snapshots, validate_shell


@dataclass(slots=True)
class CommandResult:
    status: str
    modified_files: list[str] = field(default_factory=list)
    issues: list[str] = field(default_factory=list)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="settingzsh")
    subparsers = parser.add_subparsers(dest="command", required=True)
    for name in ("setup", "update", "doctor", "migrate", "reconcile"):
        command_parser = subparsers.add_parser(name)
        command_parser.add_argument("--home", type=Path, default=Path.home())
    return parser


def _ensure_bootstrap_block(zshrc_content: str) -> str:
    if has_bootstrap_block(zshrc_content):
        content = zshrc_content
    else:
        content = zshrc_content
        if content and not content.endswith("\n"):
            content += "\n"
        content += render_bootstrap_block()

    if content and not content.endswith("\n"):
        content += "\n"
    return content


def _write_text(path: Path, content: str) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    previous = path.read_text(encoding="utf-8") if path.exists() else None
    if previous == content:
        return False
    path.write_text(content, encoding="utf-8")
    return True


def _build_reconcile_write_plan(target_home: Path) -> dict[Path, str]:
    zshrc_path = target_home / ".zshrc"
    current_zshrc = zshrc_path.read_text(encoding="utf-8") if zshrc_path.exists() else ""

    write_plan: dict[Path, str] = {
        zshrc_path: _ensure_bootstrap_block(current_zshrc),
        target_home / ".config" / "settingzsh" / "init.zsh": render_init_zsh(),
    }
    managed_dir = target_home / ".config" / "settingzsh" / "managed.d"
    for filename, default_content in render_managed_fragments().items():
        target = managed_dir / filename
        if target.exists():
            write_plan[target] = target.read_text(encoding="utf-8")
        else:
            write_plan[target] = default_content
    return write_plan


def run_reconcile(
    target_home: Path,
    *,
    validator=None,
) -> CommandResult:
    zshrc_path = target_home / ".zshrc"
    zshrc_content = zshrc_path.read_text(encoding="utf-8") if zshrc_path.exists() else ""
    runner = validator or validate_shell

    if "settingZsh:managed:" in zshrc_content:
        migrate_result = run_migrate(target_home=target_home, validator=runner)
        return CommandResult(
            status=migrate_result.status,
            modified_files=migrate_result.modified_files,
        )

    write_plan = _build_reconcile_write_plan(target_home)
    snapshots = capture_file_snapshots(list(write_plan.keys()))
    modified_files: list[str] = []
    try:
        for path, content in write_plan.items():
            changed = _write_text(path, content)
            if changed:
                modified_files.append(str(path))
        runner(target_home)
    except (subprocess.CalledProcessError, OSError, RuntimeError):
        restore_file_snapshots(snapshots, root=target_home)
        return CommandResult(status="rolled_back", modified_files=[])

    status = "reconciled" if modified_files else "no-op"
    return CommandResult(status=status, modified_files=modified_files)


def run_setup(target_home: Path, *, validator=None) -> CommandResult:
    return run_reconcile(target_home=target_home, validator=validator)


def run_update(target_home: Path, *, validator=None) -> CommandResult:
    return run_reconcile(target_home=target_home, validator=validator)


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command == "setup":
        result = run_setup(target_home=args.home)
        return 0 if result.status != "rolled_back" else 1
    if args.command == "update":
        result = run_update(target_home=args.home)
        return 0 if result.status != "rolled_back" else 1
    if args.command == "reconcile":
        result = run_reconcile(target_home=args.home)
        return 0 if result.status != "rolled_back" else 1
    if args.command == "doctor":
        result = run_doctor(target_home=args.home)
        return 0 if result.status == "ok" else 1
    if args.command == "migrate":
        result = run_migrate(target_home=args.home)
        return 0 if result.status != "rolled_back" else 1
    return 0
