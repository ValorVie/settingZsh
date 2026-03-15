from __future__ import annotations

import re

from settingzsh.shellgen import (
    render_bootstrap_file as _render_bootstrap_file,
    render_bootstrap_block as _render_bootstrap_block,
    render_init_zsh as _render_init_zsh,
    render_managed_fragments as _render_managed_fragments,
)

BOOTSTRAP_BEGIN = "# >>> settingZsh bootstrap >>>"
BOOTSTRAP_END = "# <<< settingZsh bootstrap <<<"
_BOOTSTRAP_BLOCK_RE = re.compile(
    rf"(?ms)^{re.escape(BOOTSTRAP_BEGIN)}\n.*?^{re.escape(BOOTSTRAP_END)}\n?"
)


def render_bootstrap_file() -> str:
    return _render_bootstrap_file()


def render_bootstrap_block() -> str:
    return _render_bootstrap_block()


def has_bootstrap_block(content: str) -> bool:
    return BOOTSTRAP_BEGIN in content and BOOTSTRAP_END in content


def is_bootstrap_file(content: str) -> bool:
    normalized = content.strip()
    return normalized == render_bootstrap_file().strip()


def render_init_zsh() -> str:
    return _render_init_zsh()


def render_managed_fragments() -> dict[str, str]:
    return _render_managed_fragments()


def strip_bootstrap_content(content: str) -> str:
    if is_bootstrap_file(content):
        return ""
    stripped = _BOOTSTRAP_BLOCK_RE.sub("", content, count=1)
    if stripped and not stripped.endswith("\n"):
        stripped += "\n"
    return stripped
