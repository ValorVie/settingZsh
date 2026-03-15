from __future__ import annotations

import sys
from pathlib import Path

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.legacy_import import run_legacy_import


def test_legacy_import_creates_draft_without_enabling_it(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir()
    (home / ".zshrc").write_text(
        "export OLD_VAR=1\n# >>> settingZsh bootstrap >>>\n[ -f \"$HOME/.config/settingzsh/init.zsh\" ] && source \"$HOME/.config/settingzsh/init.zsh\"\n# <<< settingZsh bootstrap <<<\n",
        encoding="utf-8",
    )

    result = run_legacy_import(target_home=home, draft=True)

    draft = home / ".config" / "settingzsh" / "local.d" / "90-legacy-import.zsh.draft"
    final_path = home / ".config" / "settingzsh" / "local.d" / "90-legacy-import.zsh"
    assert result.status == "drafted"
    assert draft.exists()
    assert draft.read_text(encoding="utf-8") == "export OLD_VAR=1\n"
    assert not final_path.exists()
