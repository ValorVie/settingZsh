from __future__ import annotations

from settingzsh.shellgen import (
    render_bootstrap_block as _render_bootstrap_block,
    render_init_zsh as _render_init_zsh,
    render_managed_fragments as _render_managed_fragments,
)

BOOTSTRAP_BEGIN = "# >>> settingZsh bootstrap >>>"
BOOTSTRAP_END = "# <<< settingZsh bootstrap <<<"


def render_bootstrap_block() -> str:
    return _render_bootstrap_block()


def has_bootstrap_block(content: str) -> bool:
    return BOOTSTRAP_BEGIN in content and BOOTSTRAP_END in content


def render_init_zsh() -> str:
    return _render_init_zsh()


def render_managed_fragments() -> dict[str, str]:
    return _render_managed_fragments()
