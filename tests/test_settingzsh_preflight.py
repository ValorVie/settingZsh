from __future__ import annotations

import sys
from pathlib import Path

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.preflight import run_preflight
from settingzsh.state import ShellValidationResult


def test_preflight_returns_safe_when_zshrc_is_missing(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()

    result = run_preflight(target_home=home)

    assert result.status == "safe"
    assert result.issues == []


def test_preflight_blocks_heavy_existing_zshrc(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()
    (home / ".zshrc").write_text(
        "autoload -Uz compinit\ncompinit\nprecmd() { :; }\n",
        encoding="utf-8",
    )

    result = run_preflight(target_home=home)

    assert result.status == "needs_adopt"
    assert "heavy_existing_shell" in result.issues
    assert "compinit" in result.details["shell_ecosystem"]
    assert "precmd" in result.details["hooks"]


def test_preflight_marks_broken_shell_from_validation_result(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()
    (home / ".zshrc").write_text("export TEST_VAR=1\n", encoding="utf-8")

    def fake_validator(_: Path) -> ShellValidationResult:
        return ShellValidationResult(
            status="warn",
            issues=["interactive_shell_warning"],
            syntax_stdout="",
            syntax_stderr="",
            interactive_stdout="",
            interactive_stderr="gitstatus failed to initialize",
        )

    result = run_preflight(target_home=home, validator=fake_validator)

    assert result.status == "broken_existing_shell"
    assert "interactive_shell_warning" in result.issues
