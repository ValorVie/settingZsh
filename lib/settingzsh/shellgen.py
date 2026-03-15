from __future__ import annotations

import platform
from pathlib import Path


_REPO_ROOT = Path(__file__).resolve().parents[2]
_TEMPLATES_DIR = _REPO_ROOT / "templates"


def _read_template(name: str) -> str:
    content = (_TEMPLATES_DIR / name).read_text(encoding="utf-8")
    if content and not content.endswith("\n"):
        content += "\n"
    return content


def _base_template_name(system_name: str) -> str:
    if system_name == "Darwin":
        return "zshrc_base_mac.zsh"
    return "zshrc_base_linux.zsh"


def render_bootstrap_block() -> str:
    lines = (
        "# >>> settingZsh bootstrap >>>",
        '[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"',
        "# <<< settingZsh bootstrap <<<",
    )
    return "\n".join(lines) + "\n"


def render_bootstrap_file() -> str:
    lines = (
        "# managed by chezmoi: settingZsh public baseline",
        'if [ -f "$HOME/.config/settingzsh/init.zsh" ]; then',
        '  source "$HOME/.config/settingzsh/init.zsh"',
        "fi",
    )
    return "\n".join(lines) + "\n"


def render_init_zsh() -> str:
    lines = (
        '[[ -n "${SETTINGZSH_LOADED:-}" ]] && return 0',
        "export SETTINGZSH_LOADED=1",
        'for file in "$HOME"/.config/settingzsh/managed.d/*.zsh(N); do',
        '  [ -f "$file" ] && source "$file"',
        "done",
        'for file in "$HOME"/.config/settingzsh/local.d/*.zsh(N); do',
        '  [ -f "$file" ] && source "$file"',
        "done",
    )
    return "\n".join(lines) + "\n"


def render_managed_fragments() -> dict[str, str]:
    system_name = platform.system()
    return {
        "10-base.zsh": _read_template(_base_template_name(system_name)),
        "40-editor.zsh": _read_template("zshrc_editor.zsh"),
    }
