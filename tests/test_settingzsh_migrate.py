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


def test_migrate_rewrites_only_settingzsh_sections(tmp_path: Path) -> None:
    home = _prepare_home_with_fixture(tmp_path, "mixed_state.zshrc")

    result = run_migrate(target_home=home)
    zshrc = (home / ".zshrc").read_text(encoding="utf-8")
    base_fragment = (
        home / ".config" / "settingzsh" / "managed.d" / "10-base.zsh"
    ).read_text(encoding="utf-8")
    editor_fragment = (
        home / ".config" / "settingzsh" / "managed.d" / "40-editor.zsh"
    ).read_text(encoding="utf-8")
    legacy_user_fragment = (
        home / ".config" / "settingzsh" / "managed.d" / "90-legacy-user.zsh"
    ).read_text(encoding="utf-8")

    assert result.status == "migrated"
    assert "# >>> settingZsh bootstrap >>>" in zshrc
    assert "settingZsh:managed:" not in zshrc
    assert "Added by Spectra" in zshrc
    assert zshrc.find("# >>> settingZsh bootstrap >>>") < zshrc.find("Added by Spectra")
    assert "export PATH=\"$PATH:$HOME/.local/bin\"" in base_fragment
    assert "lazy_nvm()" in editor_fragment
    assert "export LC_CTYPE=en_US.UTF-8" in legacy_user_fragment


def test_migrate_is_noop_for_third_party_only_zshrc(tmp_path: Path) -> None:
    home = _prepare_home_with_fixture(tmp_path, "third_party_only.zshrc")
    before = (home / ".zshrc").read_text(encoding="utf-8")

    result = run_migrate(target_home=home)
    after = (home / ".zshrc").read_text(encoding="utf-8")

    assert result.status == "no-op"
    assert result.modified_files == []
    assert after == before
    assert not (home / ".config" / "settingzsh").exists()
