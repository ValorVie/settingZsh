from __future__ import annotations

import argparse
import json
import re
import shlex
import shutil
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Literal

from settingzsh.bootstrap import is_bootstrap_file
from settingzsh.bootstrap import render_bootstrap_file
from settingzsh.bootstrap import strip_bootstrap_content

__all__ = [
    "UninstallAction",
    "UninstallPlan",
    "collect_uninstall_plan",
    "execute_uninstall",
    "is_settingzsh_powershell_bridge",
    "main",
    "render_uninstall_report",
    "restore_uninstall",
    "strip_settingzsh_bootstrap",
    "strip_settingzsh_powershell_bridge",
]

ActionKind = Literal["move", "remove-file", "rewrite-file", "report"]

_PROJECT_ROOT = Path(__file__).resolve().parents[2]

_OWNED_PATHS = (
    Path(".local/share/chezmoi"),
    Path(".config/chezmoi"),
    Path(".cache/chezmoi"),
    Path(".config/settingzsh"),
    Path(".local/share/settingzsh"),
)

_SHARED_PATHS = (
    Path(".local/bin"),
    Path(".fzf"),
    Path(".local/share/zinit/zinit.git"),
    Path(".local/share/fonts/MapleMono"),
    Path("Documents/PowerShell"),
    Path("Documents/WindowsPowerShell"),
)

_PS_PROFILE_PATHS = (
    Path("Documents/PowerShell/Microsoft.PowerShell_profile.ps1"),
    Path("Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"),
)

_SSH_PATHS = (
    Path(".ssh/config"),
    Path(".ssh/config.d/10-common.conf"),
)

_PS_BRIDGE_RE = re.compile(
    r"(?ms)(?:\n)?# managed by chezmoi: .*profile target\n"
    r"\$baselinePath = Join-Path \$HOME "
    r'"\.config/settingzsh/powershell/public-baseline\.ps1"\n'
    r"if \(Test-Path \$baselinePath\) \{\n"
    r"\s*\. \$baselinePath\n"
    r"\}\n?"
)

_SSH_CONFIG_FALLBACK = (
    "# managed by chezmoi: settingZsh public baseline\n"
    "Host *\n"
    "  ServerAliveInterval 60\n"
    "  ServerAliveCountMax 3\n"
    "  AddKeysToAgent yes\n"
    "\n"
    "Include ~/.ssh/config.d/*.conf\n"
)

_SSH_COMMON_FALLBACK = (
    "# managed by chezmoi: shared safe SSH baseline\n"
    "#\n"
    "# Add portable defaults that are safe across machines.\n"
    "# Keep vendor-specific or private host entries in private overlay files,\n"
    "# e.g. ~/.ssh/config.d/90-private.conf.\n"
)


@dataclass(slots=True)
class UninstallAction:
    kind: ActionKind
    path: Path
    detail: str = ""


@dataclass(slots=True)
class UninstallPlan:
    home: Path
    actions: list[UninstallAction] = field(default_factory=list)


def strip_settingzsh_bootstrap(content: str) -> str:
    return strip_bootstrap_content(content)


def is_settingzsh_powershell_bridge(content: str) -> bool:
    return _PS_BRIDGE_RE.fullmatch(_normalize_newlines(content).strip()) is not None


def strip_settingzsh_powershell_bridge(content: str) -> str:
    normalized = _normalize_newlines(content)
    stripped = _PS_BRIDGE_RE.sub("", normalized)
    if stripped and not stripped.endswith("\n"):
        stripped += "\n"
    return stripped


def collect_uninstall_plan(home: Path) -> UninstallPlan:
    home = _resolve_home(home)
    actions: list[UninstallAction] = []

    for relative in _OWNED_PATHS:
        path = home / relative
        _ensure_within_home(path, home)
        if path.exists():
            actions.append(UninstallAction(kind="move", path=path))

    for relative in _SHARED_PATHS:
        path = home / relative
        _ensure_within_home(path, home)
        if path.exists():
            actions.append(UninstallAction(kind="report", path=path, detail="shared"))

    zshrc = home / ".zshrc"
    _ensure_within_home(zshrc, home)
    if zshrc.exists():
        content = zshrc.read_text(encoding="utf-8")
        if is_bootstrap_file(content):
            actions.append(UninstallAction(kind="remove-file", path=zshrc, detail="pure-bootstrap"))
        else:
            stripped = strip_settingzsh_bootstrap(content)
            if stripped != content:
                kind = "remove-file" if not stripped.strip() else "rewrite-file"
                actions.append(UninstallAction(kind=kind, path=zshrc, detail="strip-bootstrap"))

    for relative in _PS_PROFILE_PATHS:
        path = home / relative
        _ensure_within_home(path, home)
        if not path.exists():
            continue
        content = path.read_text(encoding="utf-8")
        if is_settingzsh_powershell_bridge(content):
            actions.append(UninstallAction(kind="remove-file", path=path, detail="pure-bridge"))
            continue
        stripped = strip_settingzsh_powershell_bridge(content)
        if stripped != content:
            kind = "remove-file" if not stripped.strip() else "rewrite-file"
            actions.append(UninstallAction(kind=kind, path=path, detail="strip-bridge"))

    for relative in _SSH_PATHS:
        path = home / relative
        _ensure_within_home(path, home)
        if not path.exists():
            continue
        if _is_pure_ssh_baseline(path):
            actions.append(UninstallAction(kind="remove-file", path=path, detail="pure-baseline"))

    return UninstallPlan(home=home, actions=actions)


def execute_uninstall(plan: UninstallPlan, *, backup_root: Path) -> Path:
    backup_root = backup_root.expanduser().resolve()
    backup_root.mkdir(parents=True, exist_ok=True)
    backup_dir = _allocate_backup_dir(backup_root)
    owned_dir = backup_dir / "owned"
    rewritten_dir = backup_dir / "rewritten"
    owned_dir.mkdir(parents=True, exist_ok=True)
    rewritten_dir.mkdir(parents=True, exist_ok=True)

    manifest: dict[str, object] = {
        "created_at": datetime.now().isoformat(timespec="seconds"),
        "mode": "execute",
        "home": str(plan.home),
        "backup_id": backup_dir.name,
        "backup_root": str(backup_root),
        "owned": [],
        "rewritten": [],
        "shared": [],
    }

    for action in plan.actions:
        if action.kind == "report":
            manifest["shared"].append(str(action.path))
            continue

        if action.kind == "move":
            backup_path = owned_dir / _relative_to_home(plan.home, action.path)
            backup_path.parent.mkdir(parents=True, exist_ok=True)
            if not action.path.exists():
                raise FileNotFoundError(action.path)
            action.path.rename(backup_path)
            casted = manifest["owned"]  # type: ignore[assignment]
            casted.append({"path": str(action.path), "backup": str(backup_path.relative_to(backup_dir))})
            continue

        if action.kind in {"remove-file", "rewrite-file"}:
            backup_path = rewritten_dir / _relative_to_home(plan.home, action.path)
            backup_path.parent.mkdir(parents=True, exist_ok=True)
            if not action.path.exists():
                raise FileNotFoundError(action.path)
            original = action.path.read_text(encoding="utf-8")
            backup_path.write_text(original, encoding="utf-8")
            if action.kind == "remove-file":
                action.path.unlink()
            else:
                new_content = _rewrite_content(action.path, original)
                if new_content is None:
                    raise ValueError(f"rewrite action produced empty content for {action.path}")
                action.path.write_text(new_content, encoding="utf-8")
            casted = manifest["rewritten"]  # type: ignore[assignment]
            casted.append(
                {
                    "path": str(action.path),
                    "backup": str(backup_path.relative_to(backup_dir)),
                    "kind": action.kind,
                    "detail": action.detail,
                }
            )

    report = render_uninstall_report(
        plan,
        mode="execute",
        backup_id=backup_dir.name,
        backup_root=backup_root,
    )
    (backup_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    (backup_dir / "report.md").write_text(report, encoding="utf-8")
    return backup_dir


def restore_uninstall(*, home: Path, backup_root: Path, backup_id: str) -> Path | None:
    home = _resolve_home(home)
    backup_root = backup_root.expanduser().resolve()
    backup_dir = _resolve_backup_dir(backup_root, backup_id)
    manifest = json.loads((backup_dir / "manifest.json").read_text(encoding="utf-8"))
    if _resolve_home(Path(manifest["home"])) != home:
        raise ValueError("manifest home does not match --home")

    overwrite_backup_dir: Path | None = None

    for entry in _manifest_entries(manifest, "owned"):
        target = _resolve_manifest_target(home, _manifest_string(entry, "path"))
        backup_path = _resolve_manifest_backup_path(backup_dir, _manifest_string(entry, "backup"))
        overwrite_backup_dir = _snapshot_restore_conflict(
            home=home,
            target=target,
            backup_dir=backup_dir,
            overwrite_backup_dir=overwrite_backup_dir,
        )
        _restore_directory_or_file(target, backup_path)

    for entry in _manifest_entries(manifest, "rewritten"):
        target = _resolve_manifest_target(home, _manifest_string(entry, "path"))
        backup_path = _resolve_manifest_backup_path(backup_dir, _manifest_string(entry, "backup"))
        overwrite_backup_dir = _snapshot_restore_conflict(
            home=home,
            target=target,
            backup_dir=backup_dir,
            overwrite_backup_dir=overwrite_backup_dir,
        )
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(backup_path, target)

    return overwrite_backup_dir


def render_uninstall_report(
    plan: UninstallPlan,
    *,
    mode: str = "dry-run",
    backup_id: str | None = None,
    backup_root: Path | None = None,
) -> str:
    lines = [
        "# settingZsh uninstall report",
        "",
        f"- mode: `{mode}`",
        f"- home: `{plan.home}`",
    ]
    if backup_id is not None:
        lines.append(f"- backup id: `{backup_id}`")
        lines.append(f"- restore: `{_render_restore_command(plan.home, backup_root, backup_id)}`")
    lines.append("")
    _append_report_section(lines, "owned", [a for a in plan.actions if a.kind == "move"])
    _append_report_section(
        lines,
        "rewrite / remove",
        [a for a in plan.actions if a.kind in {"remove-file", "rewrite-file"}],
    )
    _append_report_section(lines, "shared", [a for a in plan.actions if a.kind == "report"])
    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="settingzsh-uninstall")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--execute", action="store_true")
    mode.add_argument("--restore")
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument(
        "--backup-root",
        type=Path,
        default=Path.home() / ".local" / "share" / "settingzsh-uninstall-backups",
    )
    args = parser.parse_args(argv)

    if args.restore:
        overwrite_backup_dir = restore_uninstall(
            home=args.home,
            backup_root=args.backup_root,
            backup_id=args.restore,
        )
        if overwrite_backup_dir is not None:
            print(f"restore overwrite backup: {overwrite_backup_dir}")
        print(f"restore complete: {args.restore}")
        return 0

    plan = collect_uninstall_plan(args.home)
    if args.dry_run:
        print(render_uninstall_report(plan, mode="dry-run"))
        return 0

    backup_dir = execute_uninstall(plan, backup_root=args.backup_root)
    print(render_uninstall_report(plan, mode="execute", backup_id=backup_dir.name))
    print(f"backup_id: {backup_dir.name}")
    return 0


def _resolve_home(home: Path) -> Path:
    return home.expanduser().resolve()


def _ensure_within_home(path: Path, home: Path) -> None:
    resolved_home = home.resolve()
    resolved_path = path.expanduser().resolve(strict=False)
    try:
        resolved_path.relative_to(resolved_home)
    except ValueError as exc:
        raise ValueError(f"path escapes --home: {path}") from exc


def _relative_to_home(home: Path, path: Path) -> Path:
    expanded = path.expanduser()
    if not expanded.is_absolute():
        expanded = home / expanded
    return expanded.relative_to(home)


def _is_pure_ssh_baseline(path: Path) -> bool:
    content = path.read_text(encoding="utf-8")
    normalized = _normalize_newlines(content).strip()
    if path.name == "config":
        expected = _load_repo_template(
            Path("home/private_dot_ssh/config.tmpl"),
            fallback=_SSH_CONFIG_FALLBACK,
        ).strip()
    else:
        expected = _load_repo_template(
            Path("home/private_dot_ssh/config.d/10-common.conf.tmpl"),
            fallback=_SSH_COMMON_FALLBACK,
        ).strip()
    return normalized == expected


def _rewrite_content(path: Path, original: str) -> str | None:
    if path.name == ".zshrc":
        stripped = strip_settingzsh_bootstrap(original)
    else:
        stripped = strip_settingzsh_powershell_bridge(original)
    if not stripped.strip():
        return None
    if not stripped.endswith("\n"):
        stripped += "\n"
    return stripped


def _restore_directory_or_file(target: Path, backup_path: Path) -> None:
    if target.exists() or target.is_symlink():
        if target.is_dir() and not target.is_symlink():
            shutil.rmtree(target)
        else:
            target.unlink()
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(backup_path), str(target))


def _allocate_backup_dir(backup_root: Path) -> Path:
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    candidate = backup_root / timestamp
    counter = 1
    while candidate.exists():
        candidate = backup_root / f"{timestamp}-{counter}"
        counter += 1
    candidate.mkdir(parents=True, exist_ok=False)
    return candidate


def _resolve_backup_dir(backup_root: Path, backup_id: str) -> Path:
    backup_id_path = Path(backup_id)
    if backup_id_path.name != backup_id or backup_id in {"", ".", ".."}:
        raise ValueError("invalid backup id")
    backup_dir = (backup_root / backup_id).resolve()
    try:
        backup_dir.relative_to(backup_root)
    except ValueError as exc:
        raise ValueError("backup id escapes --backup-root") from exc
    return backup_dir


def _resolve_manifest_backup_path(backup_dir: Path, backup_relative: str) -> Path:
    candidate = (backup_dir / backup_relative).resolve(strict=False)
    try:
        candidate.relative_to(backup_dir.resolve())
    except ValueError as exc:
        raise ValueError("manifest backup escapes backup dir") from exc
    return candidate


def _resolve_manifest_target(home: Path, target_value: str) -> Path:
    target = Path(target_value).expanduser()
    if not target.is_absolute():
        target = home / target
    _ensure_within_home(target, home)
    return target


def _manifest_entries(manifest: dict[str, object], key: str) -> list[dict[str, object]]:
    entries = manifest.get(key)
    if not isinstance(entries, list):
        raise ValueError(f"manifest {key} must be a list")
    result: list[dict[str, object]] = []
    for entry in entries:
        if not isinstance(entry, dict):
            raise ValueError(f"manifest {key} entry must be an object")
        result.append(entry)
    return result


def _manifest_string(entry: dict[str, object], key: str) -> str:
    value = entry.get(key)
    if not isinstance(value, str):
        raise ValueError(f"manifest field {key} must be a string")
    return value


def _snapshot_restore_conflict(
    *,
    home: Path,
    target: Path,
    backup_dir: Path,
    overwrite_backup_dir: Path | None,
) -> Path | None:
    _ensure_within_home(target, home)
    if not (target.exists() or target.is_symlink()):
        return overwrite_backup_dir
    if overwrite_backup_dir is None:
        overwrite_backup_dir = _allocate_backup_dir(backup_dir / "restore-overwrite")
    snapshot_path = overwrite_backup_dir / _relative_to_home(home, target)
    snapshot_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(target), str(snapshot_path))
    return overwrite_backup_dir


def _render_restore_command(home: Path, backup_root: Path | None, backup_id: str) -> str:
    parts = ["scripts/uninstall-settingzsh.sh"]
    parts.extend(["--home", shlex.quote(str(home))])
    if backup_root is not None:
        parts.extend(["--backup-root", shlex.quote(str(backup_root))])
    parts.extend(["--restore", shlex.quote(backup_id)])
    return " ".join(parts)


def _append_report_section(lines: list[str], title: str, actions: list[UninstallAction]) -> None:
    lines.append(f"## {title}")
    if not actions:
        lines.append("- none")
        lines.append("")
        return
    for action in actions:
        lines.append(f"- `{action.kind}`: `{action.path}`")
    lines.append("")


def _normalize_newlines(content: str) -> str:
    return content.replace("\r\n", "\n")


def _load_repo_template(relative_path: Path, *, fallback: str) -> str:
    template_path = _PROJECT_ROOT / relative_path
    if not template_path.is_file():
        return fallback
    return template_path.read_text(encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
