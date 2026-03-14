from __future__ import annotations

import argparse


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="settingzsh")
    subparsers = parser.add_subparsers(dest="command", required=True)
    for name in ("setup", "update", "doctor", "migrate", "reconcile"):
        subparsers.add_parser(name)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    parser.parse_args(argv)
    return 0

