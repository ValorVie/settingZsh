from __future__ import annotations

import sys
from pathlib import Path

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.adopt import run_adopt


def test_adopt_creates_backup_and_report_without_rewriting_zshrc(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()
    zshrc = home / ".zshrc"
    zshrc.write_text(
        'export PATH="$PATH:$HOME/.local/bin"\nexport API_TOKEN="secret"\n',
        encoding="utf-8",
    )
    before = zshrc.read_text(encoding="utf-8")

    result = run_adopt(target_home=home)

    assert result.status == "reported"
    assert any(".zshrc.bak." in path for path in result.modified_files)
    assert any(path.endswith(".md") for path in result.modified_files)
    assert zshrc.read_text(encoding="utf-8") == before


def test_adopt_is_noop_without_existing_zshrc(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()

    result = run_adopt(target_home=home)

    assert result.status == "no-op"
    assert result.modified_files == []
