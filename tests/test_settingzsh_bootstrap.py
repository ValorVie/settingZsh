from __future__ import annotations

import sys
from pathlib import Path

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

import settingzsh.bootstrap as bootstrap
from settingzsh.bootstrap import (
    ensure_single_bootstrap_block,
    has_bootstrap_block,
    is_bootstrap_file,
    render_bootstrap_block,
    render_bootstrap_file,
    strip_bootstrap_content,
)


def test_bootstrap_module_only_exposes_zshrc_block_utilities() -> None:
    assert hasattr(bootstrap, "ensure_single_bootstrap_block")
    assert hasattr(bootstrap, "strip_bootstrap_content")
    assert not hasattr(bootstrap, "render_init_zsh")
    assert not hasattr(bootstrap, "render_managed_fragments")


def test_render_bootstrap_block() -> None:
    block = render_bootstrap_block()
    assert "settingZsh bootstrap" in block
    assert 'source "$HOME/.config/settingzsh/init.zsh"' in block


def test_render_bootstrap_file_is_minimal_root_zshrc() -> None:
    content = render_bootstrap_file()
    assert "# managed by chezmoi: settingZsh public baseline" in content
    assert 'if [ -f "$HOME/.config/settingzsh/init.zsh" ]; then' in content
    assert is_bootstrap_file(content) is True
    assert has_bootstrap_block(content) is False


def test_strip_bootstrap_content_removes_inline_bootstrap_block() -> None:
    content = (
        "export OLD_VAR=1\n"
        "# >>> settingZsh bootstrap >>>\n"
        "[ -f \"$HOME/.config/settingzsh/init.zsh\" ] && source \"$HOME/.config/settingzsh/init.zsh\"\n"
        "# <<< settingZsh bootstrap <<<\n"
    )
    assert strip_bootstrap_content(content) == "export OLD_VAR=1\n"


def test_strip_bootstrap_content_removes_all_duplicate_bootstrap_blocks() -> None:
    block = render_bootstrap_block()
    content = f"export TEST=1\n{block}{block}"
    assert strip_bootstrap_content(content) == "export TEST=1\n"


def test_ensure_single_bootstrap_block_dedupes_existing_blocks() -> None:
    block = render_bootstrap_block()
    content = f"export TEST=1\n{block}{block}"

    normalized = ensure_single_bootstrap_block(content)

    assert normalized.count("# >>> settingZsh bootstrap >>>") == 1
    assert normalized.endswith(block)
    assert normalized.startswith("export TEST=1\n")
