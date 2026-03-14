from __future__ import annotations

import sys
from pathlib import Path

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.bootstrap import (
    render_bootstrap_block,
    render_init_zsh,
    render_managed_fragments,
)
from settingzsh.cli import main


def test_render_bootstrap_block() -> None:
    block = render_bootstrap_block()
    assert "settingZsh bootstrap" in block
    assert 'source "$HOME/.config/settingzsh/init.zsh"' in block


def test_render_init_zsh_loads_managed_fragments_once() -> None:
    content = render_init_zsh()
    assert "managed.d" in content
    assert "SETTINGZSH_LOADED" in content
    assert "*.zsh(N)" in content


def test_render_managed_fragments_shape() -> None:
    fragments = render_managed_fragments()
    assert set(fragments.keys()) == {"10-base.zsh", "40-editor.zsh"}
    assert all(isinstance(v, str) for v in fragments.values())
    assert all(v.endswith("\n") for v in fragments.values())


def test_setup_command_executes_preview_path() -> None:
    assert main(["setup"]) == 0
