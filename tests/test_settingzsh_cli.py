from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.cli import build_parser


def _extract_subcommands(parser: argparse.ArgumentParser) -> set[str]:
    for action in parser._actions:  # noqa: SLF001
        if isinstance(action, argparse._SubParsersAction):  # noqa: SLF001
            return set(action.choices.keys())
    return set()


def test_cli_exposes_expected_commands() -> None:
    parser = build_parser()
    assert {"setup", "update", "doctor", "migrate", "reconcile"} <= _extract_subcommands(
        parser
    )
