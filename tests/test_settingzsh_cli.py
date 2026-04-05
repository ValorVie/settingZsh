from __future__ import annotations

import argparse
import sys
from pathlib import Path

import pytest

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.cli import build_parser
from settingzsh.cli import main
from settingzsh.cli import run_reconcile
from settingzsh.cli import run_setup
from settingzsh.cli import run_update


def _extract_subcommands(parser: argparse.ArgumentParser) -> set[str]:
    for action in parser._actions:  # noqa: SLF001
        if isinstance(action, argparse._SubParsersAction):  # noqa: SLF001
            return set(action.choices.keys())
    return set()


def test_cli_exposes_expected_commands() -> None:
    parser = build_parser()
    assert {
        "setup",
        "update",
        "doctor",
        "migrate",
        "reconcile",
        "preflight",
        "adopt",
        "legacy-import",
    } <= _extract_subcommands(parser)


@pytest.mark.parametrize(
    ("runner", "expected_guidance"),
    [
        (run_setup, "chezmoi init --apply"),
        (run_update, "chezmoi update"),
        (run_reconcile, "chezmoi apply"),
    ],
)
def test_deprecated_write_entrypoints_only_emit_guidance(
    tmp_path: Path,
    capsys: pytest.CaptureFixture[str],
    runner,
    expected_guidance: str,
) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    before = "export TEST_VAR=1\n"
    (home / ".zshrc").write_text(before, encoding="utf-8")

    result = runner(target_home=home)
    captured = capsys.readouterr()

    assert result.status == "deprecated"
    assert result.modified_files == []
    assert expected_guidance in captured.err
    assert (home / ".zshrc").read_text(encoding="utf-8") == before
    assert not (home / ".config" / "settingzsh").exists()


@pytest.mark.parametrize(
    ("command", "expected_guidance"),
    [
        ("setup", "chezmoi init --apply"),
        ("update", "chezmoi update"),
        ("reconcile", "chezmoi apply"),
        ("migrate", "legacy-import"),
    ],
)
def test_cli_main_returns_non_success_for_deprecated_write_commands(
    tmp_path: Path,
    capsys: pytest.CaptureFixture[str],
    command: str,
    expected_guidance: str,
) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    (home / ".zshrc").write_text("export TEST_VAR=1\n", encoding="utf-8")

    exit_code = main([command, "--home", str(home)])
    captured = capsys.readouterr()

    assert exit_code == 1
    assert expected_guidance in captured.err
    assert (home / ".zshrc").read_text(encoding="utf-8") == "export TEST_VAR=1\n"
    assert not (home / ".config" / "settingzsh").exists()
