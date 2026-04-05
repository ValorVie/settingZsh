from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field
from pathlib import Path

from settingzsh.adopt import run_adopt
from settingzsh.deprecations import DEPRECATED_GUIDANCE
from settingzsh.doctor import run_doctor
from settingzsh.legacy_import import run_legacy_import
from settingzsh.migrate import run_migrate
from settingzsh.preflight import run_preflight


@dataclass(slots=True)
class CommandResult:
    status: str
    modified_files: list[str] = field(default_factory=list)
    issues: list[str] = field(default_factory=list)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="settingzsh")
    subparsers = parser.add_subparsers(dest="command", required=True)
    for name in (
        "setup",
        "update",
        "doctor",
        "migrate",
        "reconcile",
        "preflight",
        "adopt",
        "legacy-import",
    ):
        command_parser = subparsers.add_parser(name)
        command_parser.add_argument("--home", type=Path, default=Path.home())
    return parser


def _deprecated_command(command: str) -> CommandResult:
    message = DEPRECATED_GUIDANCE[command]
    print(message, file=sys.stderr)
    return CommandResult(status="deprecated", issues=[message])


def run_reconcile(
    target_home: Path,
    *,
    validator=None,
) -> CommandResult:
    del target_home, validator
    return _deprecated_command("reconcile")


def run_setup(target_home: Path, *, validator=None) -> CommandResult:
    del target_home, validator
    return _deprecated_command("setup")


def run_update(target_home: Path, *, validator=None) -> CommandResult:
    del target_home, validator
    return _deprecated_command("update")


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command == "setup":
        run_setup(target_home=args.home)
        return 1
    if args.command == "update":
        run_update(target_home=args.home)
        return 1
    if args.command == "reconcile":
        run_reconcile(target_home=args.home)
        return 1
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
    if args.command == "migrate":
        run_migrate(target_home=args.home)
        return 1
    return 0
