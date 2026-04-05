from __future__ import annotations

import shutil
import sys
from pathlib import Path

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.migrate import run_migrate


def _prepare_home_with_fixture(tmp_path: Path, fixture_name: str) -> Path:
    fixture = _PROJECT_ROOT / "tests" / "fixtures" / "zshrc" / fixture_name
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(fixture, home / ".zshrc")
    return home


def test_migrate_is_deprecated_no_op_and_does_not_write_files(tmp_path: Path, capsys) -> None:
    home = _prepare_home_with_fixture(tmp_path, "mixed_state.zshrc")
    original = (home / ".zshrc").read_text(encoding="utf-8")
    called = False

    def validator(_: Path) -> None:
        nonlocal called
        called = True
        raise AssertionError("validator should not be called")

    result = run_migrate(target_home=home, validator=validator)
    captured = capsys.readouterr()

    assert result.status == "deprecated"
    assert result.modified_files == []
    assert result.managed_sections == []
    assert result.issues and "legacy-import" in result.issues[0]
    assert called is False
    assert (home / ".zshrc").read_text(encoding="utf-8") == original
    assert not (home / ".config" / "settingzsh").exists()
    assert "legacy-import" in captured.err


def test_migrate_is_no_op_without_existing_zshrc(tmp_path: Path, capsys) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)

    result = run_migrate(target_home=home)
    captured = capsys.readouterr()

    assert result.status == "deprecated"
    assert result.modified_files == []
    assert result.managed_sections == []
    assert result.issues and "legacy-import" in result.issues[0]
    assert "legacy-import" in captured.err
    assert not (home / ".config" / "settingzsh").exists()
