from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


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


def validate_shell(
    target_home: Path,
    *,
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> None:
    env = _build_validation_env(target_home)
    validate_zsh_syntax(target_home, runner=runner)
    runner(
        ["zsh", "-i", "-c", "exit"],
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )


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
