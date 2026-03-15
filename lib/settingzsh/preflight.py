from __future__ import annotations

import re
from pathlib import Path
from typing import Callable

from settingzsh.reconcile import inspect_shell_validation
from settingzsh.state import PreflightResult
from settingzsh.state import ShellValidationResult

_DETAIL_KEYS = ("shell_ecosystem", "hooks", "integrations", "secrets")
_SHELL_ECOSYSTEM_PATTERNS = (
    ("zinit", re.compile(r"\bzinit\b")),
    ("oh-my-zsh", re.compile(r"oh-my-zsh|^\s*ZSH=", re.MULTILINE)),
    ("compinit", re.compile(r"\bcompinit\b")),
    ("powerlevel10k", re.compile(r"p10k|POWERLEVEL9K_", re.IGNORECASE)),
    ("openspec_completion", re.compile(r"OPENSPEC:", re.IGNORECASE)),
)
_HOOK_PATTERNS = (
    ("precmd", re.compile(r"^\s*(?:function\s+)?precmd\s*\(", re.MULTILINE)),
    ("precmd_functions", re.compile(r"\bprecmd_functions\b")),
    ("chpwd_functions", re.compile(r"\bchpwd_functions\b")),
)
_INTEGRATION_PATTERNS = (
    ("brew_shellenv", re.compile(r"brew shellenv")),
    ("nvm", re.compile(r"\bNVM_DIR\b|\bnvm\b")),
    ("bun", re.compile(r"\bBUN_INSTALL\b|\bbun\b")),
    ("conda", re.compile(r"\bconda\b")),
)
_SECRET_PATTERNS = (
    ("api_key", re.compile(r"(?im)\b[A-Z0-9_]*(?:API[_-]?KEY|KEY)\b\s*=")),
    ("token", re.compile(r"(?im)\b[A-Z0-9_]*TOKEN\b\s*=")),
    ("secret", re.compile(r"(?im)\b[A-Z0-9_]*SECRET\b\s*=")),
    ("password", re.compile(r"(?im)\b[A-Z0-9_]*PASSWORD\b\s*=")),
)


def inspect_zshrc_content(content: str) -> dict[str, list[str]]:
    details = {key: [] for key in _DETAIL_KEYS}
    for label, pattern in _SHELL_ECOSYSTEM_PATTERNS:
        if pattern.search(content):
            details["shell_ecosystem"].append(label)
    for label, pattern in _HOOK_PATTERNS:
        if pattern.search(content):
            details["hooks"].append(label)
    for label, pattern in _INTEGRATION_PATTERNS:
        if pattern.search(content):
            details["integrations"].append(label)
    for label, pattern in _SECRET_PATTERNS:
        if pattern.search(content):
            details["secrets"].append(label)
    return details


def run_preflight(
    target_home: Path,
    *,
    validator: Callable[[Path], ShellValidationResult] | None = None,
) -> PreflightResult:
    zshrc_path = target_home / ".zshrc"
    if not zshrc_path.exists():
        return PreflightResult(
            status="safe",
            details={key: [] for key in _DETAIL_KEYS},
        )

    content = zshrc_path.read_text(encoding="utf-8")
    details = inspect_zshrc_content(content)
    validation = (validator or inspect_shell_validation)(target_home)
    if validation.issues:
        return PreflightResult(
            status="broken_existing_shell",
            issues=list(dict.fromkeys(validation.issues)),
            details=details,
        )

    issues: list[str] = []
    if "settingZsh:managed:" in content or "settingZsh:user:" in content:
        issues.append("legacy_markers")

    if details["shell_ecosystem"] or details["hooks"] or details["secrets"]:
        issues.append("heavy_existing_shell")
        if details["secrets"]:
            issues.append("secret_smells")
        return PreflightResult(status="needs_adopt", issues=issues, details=details)

    return PreflightResult(status="safe", issues=issues, details=details)
