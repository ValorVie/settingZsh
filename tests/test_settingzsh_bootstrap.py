from __future__ import annotations

import sys
from pathlib import Path

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.bootstrap import (
    is_bootstrap_file,
    render_bootstrap_block,
    render_bootstrap_file,
    render_init_zsh,
    render_managed_fragments,
    strip_bootstrap_content,
)
from settingzsh.cli import main


def test_render_bootstrap_block() -> None:
    block = render_bootstrap_block()
    assert "settingZsh bootstrap" in block
    assert 'source "$HOME/.config/settingzsh/init.zsh"' in block


def test_render_bootstrap_file_is_minimal_root_zshrc() -> None:
    content = render_bootstrap_file()
    assert "# managed by chezmoi: settingZsh public baseline" in content
    assert 'if [ -f "$HOME/.config/settingzsh/init.zsh" ]; then' in content
    assert is_bootstrap_file(content) is True


def test_render_init_zsh_loads_managed_fragments_once() -> None:
    content = render_init_zsh()
    assert "managed.d" in content
    assert "local.d" in content
    assert "SETTINGZSH_LOADED" in content
    assert "*.zsh(N)" in content


def test_render_managed_fragments_shape() -> None:
    fragments = render_managed_fragments()
    assert set(fragments.keys()) == {"10-base.zsh", "40-editor.zsh"}
    assert all(isinstance(v, str) for v in fragments.values())
    assert all(v.endswith("\n") for v in fragments.values())


def test_render_managed_fragments_use_real_shell_content() -> None:
    fragments = render_managed_fragments()
    assert "ZINIT_HOME=" in fragments["10-base.zsh"]
    assert "lazy_nvm()" in fragments["40-editor.zsh"]
    assert "SETTINGZSH_DISABLE_EDITOR_SHELL" in fragments["40-editor.zsh"]


def test_strip_bootstrap_content_removes_inline_bootstrap_block() -> None:
    content = (
        "export OLD_VAR=1\n"
        "# >>> settingZsh bootstrap >>>\n"
        "[ -f \"$HOME/.config/settingzsh/init.zsh\" ] && source \"$HOME/.config/settingzsh/init.zsh\"\n"
        "# <<< settingZsh bootstrap <<<\n"
    )
    assert strip_bootstrap_content(content) == "export OLD_VAR=1\n"


def test_setup_command_executes_preview_path(tmp_path: Path, monkeypatch) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr("settingzsh.cli.validate_shell", lambda _: None)
    assert main(["setup", "--home", str(home)]) == 0
