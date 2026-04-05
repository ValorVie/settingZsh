from __future__ import annotations

import re

BOOTSTRAP_BEGIN = "# >>> settingZsh bootstrap >>>"
BOOTSTRAP_END = "# <<< settingZsh bootstrap <<<"
_BOOTSTRAP_FILE = (
    "# managed by chezmoi: settingZsh public baseline\n"
    "if [ -f \"$HOME/.config/settingzsh/init.zsh\" ]; then\n"
    "  source \"$HOME/.config/settingzsh/init.zsh\"\n"
    "fi\n"
)
_BOOTSTRAP_BLOCK = (
    "# >>> settingZsh bootstrap >>>\n"
    "[ -f \"$HOME/.config/settingzsh/init.zsh\" ] && source \"$HOME/.config/settingzsh/init.zsh\"\n"
    "# <<< settingZsh bootstrap <<<\n"
)
_BOOTSTRAP_BLOCK_RE = re.compile(
    rf"(?ms)(?:\n)?{re.escape(BOOTSTRAP_BEGIN)}\n.*?{re.escape(BOOTSTRAP_END)}\n?"
)

__all__ = [
    "BOOTSTRAP_BEGIN",
    "BOOTSTRAP_END",
    "ensure_single_bootstrap_block",
    "has_bootstrap_block",
    "is_bootstrap_file",
    "render_bootstrap_block",
    "render_bootstrap_file",
    "strip_bootstrap_content",
]


def render_bootstrap_file() -> str:
    return _BOOTSTRAP_FILE


def render_bootstrap_block() -> str:
    return _BOOTSTRAP_BLOCK


def has_bootstrap_block(content: str) -> bool:
    return BOOTSTRAP_BEGIN in content and BOOTSTRAP_END in content


def is_bootstrap_file(content: str) -> bool:
    return content.strip() == _BOOTSTRAP_FILE.strip()


def strip_bootstrap_content(content: str) -> str:
    if is_bootstrap_file(content):
        return ""
    stripped = _BOOTSTRAP_BLOCK_RE.sub("", content)
    if stripped and not stripped.endswith("\n"):
        stripped += "\n"
    return stripped


def ensure_single_bootstrap_block(content: str) -> str:
    if not content.strip():
        return render_bootstrap_file()
    if is_bootstrap_file(content):
        return render_bootstrap_file()
    stripped = strip_bootstrap_content(content)
    if not stripped.strip():
        return render_bootstrap_block()
    if not stripped.endswith("\n"):
        stripped += "\n"
    return stripped + render_bootstrap_block()
