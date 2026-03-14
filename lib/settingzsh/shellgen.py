from __future__ import annotations


def render_bootstrap_block() -> str:
    lines = (
        "# >>> settingZsh bootstrap >>>",
        '[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"',
        "# <<< settingZsh bootstrap <<<",
    )
    return "\n".join(lines) + "\n"


def render_init_zsh() -> str:
    lines = (
        '[[ -n "${SETTINGZSH_LOADED:-}" ]] && return 0',
        "export SETTINGZSH_LOADED=1",
        'for file in "$HOME"/.config/settingzsh/managed.d/*.zsh(N); do',
        '  [ -f "$file" ] && source "$file"',
        "done",
    )
    return "\n".join(lines) + "\n"


def render_managed_fragments() -> dict[str, str]:
    return {
        "10-base.zsh": "# settingZsh managed base fragment\n",
        "40-editor.zsh": "# settingZsh managed editor fragment\n",
    }
