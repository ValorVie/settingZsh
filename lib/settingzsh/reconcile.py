from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from settingzsh.state import ShellValidationResult

_INTERACTIVE_WARNING_SNIPPETS = (
    "gitstatus failed to initialize",
    "can't change option: monitor",
    "can't change option: zle",
)


@dataclass(slots=True)
class FileSnapshot:
    path: Path
    existed: bool
    content: str


def capture_file_snapshots(paths: list[Path]) -> list[FileSnapshot]:
    snapshots: list[FileSnapshot] = []
    for path in paths:
        if path.exists():
            snapshots.append(
                FileSnapshot(path=path, existed=True, content=path.read_text(encoding="utf-8"))
            )
        else:
            snapshots.append(FileSnapshot(path=path, existed=False, content=""))
    return snapshots


def restore_file_snapshots(snapshots: list[FileSnapshot], *, root: Path) -> None:
    root = root.resolve()
    for snapshot in snapshots:
        if snapshot.existed:
            snapshot.path.parent.mkdir(parents=True, exist_ok=True)
            snapshot.path.write_text(snapshot.content, encoding="utf-8")
            continue

        if snapshot.path.exists():
            snapshot.path.unlink()
            _prune_empty_parents(snapshot.path.parent, stop=root)


def validate_zsh_syntax(
    target_home: Path,
    *,
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> None:
    zshrc = target_home / ".zshrc"
    env = _build_validation_env(target_home)

    runner(
        ["zsh", "-n", str(zshrc)],
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )


def inspect_shell_validation(
    target_home: Path,
    *,
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> ShellValidationResult:
    env = _build_validation_env(target_home)
    zshrc = target_home / ".zshrc"
    syntax = runner(
        ["zsh", "-n", str(zshrc)],
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )
    issues: list[str] = []
    if syntax.returncode != 0:
        issues.append("shell_validation_failed")
        return ShellValidationResult(
            status="warn",
            issues=issues,
            syntax_stdout=syntax.stdout,
            syntax_stderr=syntax.stderr,
        )

    interactive = runner(
        ["zsh", "-i", "-c", "exit"],
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )
    combined_output = "\n".join(
        part for part in (interactive.stdout, interactive.stderr) if part
    )
    if interactive.returncode != 0:
        issues.append("interactive_shell_failed")
    if any(snippet in combined_output for snippet in _INTERACTIVE_WARNING_SNIPPETS):
        issues.append("interactive_shell_warning")

    status = "warn" if issues else "ok"
    return ShellValidationResult(
        status=status,
        issues=issues,
        syntax_stdout=syntax.stdout,
        syntax_stderr=syntax.stderr,
        interactive_stdout=interactive.stdout,
        interactive_stderr=interactive.stderr,
    )


def validate_shell(
    target_home: Path,
    *,
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> None:
    result = inspect_shell_validation(target_home, runner=runner)
    if result.issues:
        raise RuntimeError(",".join(result.issues))


def _prune_empty_parents(path: Path, *, stop: Path) -> None:
    current = path
    while current.exists() and current != stop:
        try:
            current.rmdir()
        except OSError:
            break
        current = current.parent


def _build_validation_env(target_home: Path) -> dict[str, str]:
    env = os.environ.copy()
    env["HOME"] = str(target_home)
    env["ZDOTDIR"] = str(target_home)
    return env
