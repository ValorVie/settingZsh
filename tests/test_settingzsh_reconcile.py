from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.migrate import run_migrate
from settingzsh.doctor import run_doctor
from settingzsh.reconcile import validate_shell


def _prepare_home_with_fixture(tmp_path: Path, fixture_name: str) -> Path:
    fixture = _PROJECT_ROOT / "tests" / "fixtures" / "zshrc" / fixture_name
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(fixture, home / ".zshrc")
    return home


def test_failed_validation_restores_original_zshrc(tmp_path: Path) -> None:
    home = _prepare_home_with_fixture(tmp_path, "mixed_state.zshrc")
    original = (home / ".zshrc").read_text(encoding="utf-8")

    def failing_validator(_: Path) -> None:
        raise subprocess.CalledProcessError(1, ["zsh", "-n"])

    result = run_migrate(target_home=home, validator=failing_validator)
    assert result.status == "rolled_back"
    assert (home / ".zshrc").read_text(encoding="utf-8") == original
    assert not (home / ".config" / "settingzsh").exists()


def test_failed_validation_restores_existing_managed_fragment(tmp_path: Path) -> None:
    home = _prepare_home_with_fixture(tmp_path, "mixed_state.zshrc")
    managed_dir = home / ".config" / "settingzsh" / "managed.d"
    managed_dir.mkdir(parents=True, exist_ok=True)
    existing_base = managed_dir / "10-base.zsh"
    existing_base.write_text("# pre-existing\n", encoding="utf-8")

    def failing_validator(_: Path) -> None:
        raise subprocess.CalledProcessError(1, ["zsh", "-n"])

    result = run_migrate(target_home=home, validator=failing_validator)
    assert result.status == "rolled_back"
    assert existing_base.read_text(encoding="utf-8") == "# pre-existing\n"
    assert not (managed_dir / "40-editor.zsh").exists()
    assert not (managed_dir / "90-legacy-user.zsh").exists()
    assert not (home / ".config" / "settingzsh" / "init.zsh").exists()


def test_doctor_uses_syntax_only_validation_by_default(
    tmp_path: Path, monkeypatch
) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    (home / ".zshrc").write_text("export TEST_VAR=1\n", encoding="utf-8")
    calls: list[Path] = []

    def fake_validator(target_home: Path) -> None:
        calls.append(target_home)

    monkeypatch.setattr("settingzsh.doctor.validate_zsh_syntax", fake_validator)

    result = run_doctor(target_home=home)
    assert result.status == "ok"
    assert result.issues == []
    assert calls == [home]


def test_failed_validation_rolls_back_paths_from_write_plan(
    tmp_path: Path, monkeypatch
) -> None:
    home = _prepare_home_with_fixture(tmp_path, "mixed_state.zshrc")
    dynamic_path = home / ".config" / "settingzsh" / "managed.d" / "50-dynamic.zsh"
    dynamic_path.parent.mkdir(parents=True, exist_ok=True)
    dynamic_path.write_text("# pre-existing dynamic\n", encoding="utf-8")
    called = False

    def fake_build_write_plan(
        *,
        target_home: Path,
        extracted_managed: dict[str, str],
        legacy_user: str,
    ) -> dict[Path, str]:
        nonlocal called
        called = True
        return {
            dynamic_path: "# replaced dynamic\n",
            target_home / ".zshrc": "# replaced zshrc\n",
        }

    def failing_validator(_: Path) -> None:
        raise subprocess.CalledProcessError(1, ["zsh", "-n"])

    monkeypatch.setattr("settingzsh.migrate._build_write_plan", fake_build_write_plan)
    result = run_migrate(target_home=home, validator=failing_validator)
    assert called is True
    assert result.status == "rolled_back"
    assert dynamic_path.read_text(encoding="utf-8") == "# pre-existing dynamic\n"


def test_validate_shell_runs_syntax_and_interactive_checks(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    (home / ".zshrc").write_text("export TEST_VAR=1\n", encoding="utf-8")

    calls: list[tuple[list[str], dict[str, str]]] = []

    def fake_run(
        cmd: list[str], *, check: bool, capture_output: bool, text: bool, env: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        assert check is True
        assert capture_output is True
        assert text is True
        calls.append((cmd, env))
        return subprocess.CompletedProcess(cmd, 0, "", "")

    validate_shell(home, runner=fake_run)

    assert calls[0][0] == ["zsh", "-n", str(home / ".zshrc")]
    assert calls[1][0] == ["zsh", "-i", "-c", "exit"]
    assert calls[1][1]["ZDOTDIR"] == str(home)
    assert calls[1][1]["HOME"] == str(home)
