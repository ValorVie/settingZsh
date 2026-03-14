from __future__ import annotations

import argparse
from pathlib import Path


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="settingzsh")
    subparsers = parser.add_subparsers(dest="command", required=True)
    for name in ("setup", "update", "doctor", "migrate", "reconcile"):
        subparsers.add_parser(name)
    return parser


def _run_setup_preview() -> None:
    from settingzsh.bootstrap import (
        render_bootstrap_block,
        render_init_zsh,
        render_managed_fragments,
    )

    # Task 2 only wires modules together; file I/O will be implemented later.
    _ = (render_bootstrap_block(), render_init_zsh(), render_managed_fragments())


def _run_doctor() -> None:
    from settingzsh.doctor import run_doctor

    _ = run_doctor(target_home=Path.home())


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command == "setup":
        _run_setup_preview()
    elif args.command == "doctor":
        _run_doctor()
    return 0
