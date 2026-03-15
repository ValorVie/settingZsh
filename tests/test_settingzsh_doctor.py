from __future__ import annotations

import shutil
import sys
from pathlib import Path

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.doctor import run_doctor
from settingzsh.state import ShellValidationResult


def _prepare_home_with_fixture(tmp_path: Path, fixture_name: str) -> Path:
    fixture = _PROJECT_ROOT / "tests" / "fixtures" / "zshrc" / fixture_name
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(fixture, home / ".zshrc")
    return home


def test_doctor_reports_legacy_markers_without_modifying_files(tmp_path: Path) -> None:
    home = _prepare_home_with_fixture(tmp_path, "legacy_markers.zshrc")
    before = (home / ".zshrc").read_text(encoding="utf-8")

    result = run_doctor(target_home=home)

    assert result.status == "warn"
    assert "legacy_markers" in result.issues
    assert result.modified_files == []
    assert (home / ".zshrc").read_text(encoding="utf-8") == before


def test_doctor_returns_ok_for_third_party_only_zshrc(tmp_path: Path) -> None:
    home = _prepare_home_with_fixture(tmp_path, "third_party_only.zshrc")

    result = run_doctor(target_home=home)

    assert result.status == "ok"
    assert result.issues == []
    assert result.modified_files == []


def test_doctor_warns_for_duplicate_compinit_and_precmd_mix(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    (home / ".zshrc").write_text(
        "autoload -Uz compinit\ncompinit\ncompinit\nprecmd() { :; }\nprecmd_functions+=(other_hook)\n",
        encoding="utf-8",
    )

    result = run_doctor(target_home=home)

    assert result.status == "warn"
    assert "duplicate_compinit" in result.issues
    assert "precmd_override" in result.issues


def test_doctor_warns_when_interactive_shell_outputs_known_errors(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
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

    result = run_doctor(target_home=home, validator=fake_validator)

    assert result.status == "warn"
    assert "interactive_shell_warning" in result.issues
