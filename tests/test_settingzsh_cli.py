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
from settingzsh.cli import run_reconcile


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


def test_reconcile_writes_bootstrap_and_managed_files(
    tmp_path: Path, monkeypatch
) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    (home / ".zshrc").write_text("export TEST_VAR=1\n", encoding="utf-8")

    monkeypatch.setattr("settingzsh.cli.validate_shell", lambda _: None)
    result = run_reconcile(target_home=home)

    zshrc = (home / ".zshrc").read_text(encoding="utf-8")
    init_zsh = (home / ".config" / "settingzsh" / "init.zsh").read_text(encoding="utf-8")

    assert result.status == "reconciled"
    assert "# >>> settingZsh bootstrap >>>" in zshrc
    assert "SETTINGZSH_LOADED" in init_zsh
    assert (home / ".config" / "settingzsh" / "managed.d" / "10-base.zsh").exists()


def test_reconcile_legacy_markers_routes_to_migrate(
    tmp_path: Path, monkeypatch
) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    (home / ".zshrc").write_text(
        "# === settingZsh:managed:zsh-base:begin ===\nexport A=1\n# === settingZsh:managed:zsh-base:end ===\n",
        encoding="utf-8",
    )
    monkeypatch.setattr("settingzsh.cli.validate_shell", lambda _: None)
    result = run_reconcile(target_home=home)
    assert result.status in {"migrated", "reconciled"}
    assert "# >>> settingZsh bootstrap >>>" in (home / ".zshrc").read_text(encoding="utf-8")
