from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

from settingzsh.bootstrap import (
    has_bootstrap_block,
    render_bootstrap_block,
    render_init_zsh,
    render_managed_fragments,
)

_BEGIN_RE = re.compile(
    r"^\s*#\s*===\s*settingZsh:(managed:[^:]+|user):begin\s*===\s*$"
)


@dataclass(slots=True)
class MigrateResult:
    status: str
    managed_sections: list[str] = field(default_factory=list)
    modified_files: list[str] = field(default_factory=list)


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _extract_settingzsh_blocks(
    zshrc_content: str,
) -> tuple[list[str], dict[str, str], str, bool, int | None]:
    lines = zshrc_content.splitlines(keepends=True)
    kept: list[str] = []
    managed: dict[str, str] = {}
    legacy_user = ""
    removed_any = False
    first_removed_index: int | None = None

    idx = 0
    while idx < len(lines):
        line = lines[idx]
        begin_match = _BEGIN_RE.match(line.rstrip("\n"))
        if begin_match is None:
            kept.append(line)
            idx += 1
            continue

        marker_name = begin_match.group(1)
        end_re = re.compile(
            rf"^\s*#\s*===\s*settingZsh:{re.escape(marker_name)}:end\s*===\s*$"
        )
        j = idx + 1
        block_lines: list[str] = []
        found_end = False
        while j < len(lines):
            end_line = lines[j]
            if end_re.match(end_line.rstrip("\n")):
                found_end = True
                break
            block_lines.append(end_line)
            j += 1

        if not found_end:
            # Keep unmatched begin marker as-is; Task 5 will handle advanced recovery.
            kept.append(line)
            idx += 1
            continue

        removed_any = True
        if first_removed_index is None:
            first_removed_index = len(kept)
        block_content = "".join(block_lines)
        if marker_name.startswith("managed:"):
            section = marker_name.split(":", 1)[1]
            managed[section] = block_content
        elif marker_name == "user":
            legacy_user = block_content

        idx = j + 1

    return kept, managed, legacy_user, removed_any, first_removed_index


def _insert_bootstrap_at(content_lines: list[str], insert_index: int | None) -> str:
    content = "".join(content_lines)
    if has_bootstrap_block(content):
        return content

    idx = len(content_lines) if insert_index is None else max(0, min(insert_index, len(content_lines)))
    bootstrap_lines = render_bootstrap_block().splitlines(keepends=True)
    merged_lines = content_lines[:idx] + bootstrap_lines + content_lines[idx:]
    merged = "".join(merged_lines)
    if merged and not merged.endswith("\n"):
        merged += "\n"
    return merged


def run_migrate(target_home: Path) -> MigrateResult:
    zshrc_path = target_home / ".zshrc"
    zshrc_content = ""
    if zshrc_path.exists():
        zshrc_content = zshrc_path.read_text(encoding="utf-8")

    (
        kept_lines,
        extracted_managed,
        legacy_user,
        removed_any,
        first_removed_index,
    ) = _extract_settingzsh_blocks(zshrc_content)

    if not removed_any:
        return MigrateResult(
            status="no-op",
            managed_sections=[],
            modified_files=[],
        )

    config_root = target_home / ".config" / "settingzsh"
    managed_dir = config_root / "managed.d"
    defaults = render_managed_fragments()

    managed_map = {
        "zsh-base": "10-base.zsh",
        "editor": "40-editor.zsh",
    }
    modified_files: list[str] = []
    for section, filename in managed_map.items():
        fallback = defaults.get(filename, "")
        content = extracted_managed.get(section, fallback)
        if content and not content.endswith("\n"):
            content += "\n"
        target = managed_dir / filename
        _write_text(target, content)
        modified_files.append(str(target))

    if legacy_user.strip():
        legacy_path = managed_dir / "90-legacy-user.zsh"
        legacy_content = legacy_user if legacy_user.endswith("\n") else f"{legacy_user}\n"
        _write_text(legacy_path, legacy_content)
        modified_files.append(str(legacy_path))

    init_path = config_root / "init.zsh"
    _write_text(init_path, render_init_zsh())
    modified_files.append(str(init_path))

    migrated_zshrc = _insert_bootstrap_at(kept_lines, first_removed_index)
    _write_text(zshrc_path, migrated_zshrc)
    modified_files.append(str(zshrc_path))

    status = "migrated" if removed_any else "no-op"
    return MigrateResult(
        status=status,
        managed_sections=sorted(extracted_managed.keys()),
        modified_files=modified_files,
    )
