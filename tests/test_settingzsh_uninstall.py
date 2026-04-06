from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.bootstrap import render_bootstrap_file
from settingzsh.uninstall import collect_uninstall_plan
from settingzsh.uninstall import execute_uninstall
from settingzsh.uninstall import is_settingzsh_powershell_bridge
from settingzsh.uninstall import render_uninstall_report
from settingzsh.uninstall import restore_uninstall
from settingzsh.uninstall import strip_settingzsh_bootstrap
from settingzsh.uninstall import strip_settingzsh_powershell_bridge


def _action(plan, target: Path):
    for action in plan.actions:
        if action.path == target:
            return action
    raise AssertionError(f"missing action for {target}")


def _write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _template(relative_path: str) -> str:
    return (_PROJECT_ROOT / relative_path).read_text(encoding="utf-8")


def test_collect_uninstall_plan_classifies_owned_shared_and_rewrite_actions(
    tmp_path: Path,
) -> None:
    home = tmp_path / "home"
    owned_paths = [
        home / ".local" / "share" / "chezmoi",
        home / ".config" / "chezmoi",
        home / ".cache" / "chezmoi",
        home / ".config" / "settingzsh",
        home / ".local" / "share" / "settingzsh",
    ]
    shared_paths = [
        home / ".local" / "bin",
        home / ".fzf",
        home / ".local" / "share" / "zinit" / "zinit.git",
        home / ".local" / "share" / "fonts" / "MapleMono",
        home / "Documents" / "PowerShell",
        home / "Documents" / "WindowsPowerShell",
    ]
    for path in owned_paths + shared_paths:
        path.mkdir(parents=True, exist_ok=True)

    _write(home / ".zshrc", render_bootstrap_file())
    _write(
        home / "Documents" / "PowerShell" / "Microsoft.PowerShell_profile.ps1",
        "# managed by chezmoi: PowerShell 7+ profile target\n"
        '$baselinePath = Join-Path $HOME ".config/settingzsh/powershell/public-baseline.ps1"\n'
        "if (Test-Path $baselinePath) {\n"
        "    . $baselinePath\n"
        "}\n",
    )
    _write(
        home / "Documents" / "WindowsPowerShell" / "Microsoft.PowerShell_profile.ps1",
        "# managed by chezmoi: Windows PowerShell 5.1 profile target\n"
        '$baselinePath = Join-Path $HOME ".config/settingzsh/powershell/public-baseline.ps1"\n'
        "if (Test-Path $baselinePath) {\n"
        "    . $baselinePath\n"
        "}\n",
    )
    _write(
        home / ".ssh" / "config",
        _template("home/private_dot_ssh/config.tmpl"),
    )
    _write(
        home / ".ssh" / "config.d" / "10-common.conf",
        _template("home/private_dot_ssh/config.d/10-common.conf.tmpl"),
    )

    plan = collect_uninstall_plan(home)

    for path in owned_paths:
        assert _action(plan, path).kind == "move"
    for path in shared_paths:
        assert _action(plan, path).kind == "report"
    assert _action(plan, home / ".zshrc").kind == "remove-file"
    assert _action(plan, home / "Documents" / "PowerShell" / "Microsoft.PowerShell_profile.ps1").kind == "remove-file"
    assert _action(plan, home / "Documents" / "WindowsPowerShell" / "Microsoft.PowerShell_profile.ps1").kind == "remove-file"
    assert _action(plan, home / ".ssh" / "config").kind == "remove-file"
    assert _action(plan, home / ".ssh" / "config.d" / "10-common.conf").kind == "remove-file"


def test_collect_uninstall_plan_strips_inline_bootstrap_and_leaves_user_content(
    tmp_path: Path,
) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    _write(
        home / ".zshrc",
        "export TEST_VAR=1\n"
        "# >>> settingZsh bootstrap >>>\n"
        '[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"\n'
        "# <<< settingZsh bootstrap <<<\n",
    )
    _write(
        home / "Documents" / "PowerShell" / "Microsoft.PowerShell_profile.ps1",
        "Set-StrictMode -Version Latest\n"
        "# managed by chezmoi: PowerShell 7+ profile target\n"
        '$baselinePath = Join-Path $HOME ".config/settingzsh/powershell/public-baseline.ps1"\n'
        "if (Test-Path $baselinePath) {\n"
        "    . $baselinePath\n"
        "}\n",
    )

    plan = collect_uninstall_plan(home)

    assert _action(plan, home / ".zshrc").kind == "rewrite-file"
    assert _action(plan, home / "Documents" / "PowerShell" / "Microsoft.PowerShell_profile.ps1").kind == "rewrite-file"
    assert strip_settingzsh_bootstrap((home / ".zshrc").read_text(encoding="utf-8")).startswith("export TEST_VAR=1")


def test_collect_uninstall_plan_rejects_paths_outside_home(tmp_path: Path) -> None:
    home = tmp_path / "home"
    outside = tmp_path / "outside"
    outside.mkdir(parents=True, exist_ok=True)
    (home / ".config").mkdir(parents=True, exist_ok=True)
    (home / ".config" / "settingzsh").symlink_to(outside)

    try:
        collect_uninstall_plan(home)
    except ValueError as exc:
        assert "home" in str(exc)
    else:
        raise AssertionError("collect_uninstall_plan should reject symlink escapes")


def test_execute_uninstall_writes_manifest_report_and_restore_round_trips(
    tmp_path: Path,
) -> None:
    home = tmp_path / "home"
    backup_root = tmp_path / "backups"
    owned_dir = home / ".config" / "settingzsh"
    shared_dir = home / ".local" / "bin"
    owned_dir.mkdir(parents=True, exist_ok=True)
    shared_dir.mkdir(parents=True, exist_ok=True)
    original_zshrc = (
        "export TEST_VAR=1\n"
        "# >>> settingZsh bootstrap >>>\n"
        '[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"\n'
        "# <<< settingZsh bootstrap <<<\n"
    )
    _write(home / ".zshrc", original_zshrc)
    _write(
        home / "Documents" / "PowerShell" / "Microsoft.PowerShell_profile.ps1",
        "# managed by chezmoi: PowerShell 7+ profile target\n"
        '$baselinePath = Join-Path $HOME ".config/settingzsh/powershell/public-baseline.ps1"\n'
        "if (Test-Path $baselinePath) {\n"
        "    . $baselinePath\n"
        "}\n",
    )
    _write(home / ".ssh" / "config", _template("home/private_dot_ssh/config.tmpl"))
    _write(
        home / ".ssh" / "config.d" / "10-common.conf",
        _template("home/private_dot_ssh/config.d/10-common.conf.tmpl"),
    )

    plan = collect_uninstall_plan(home)
    backup_dir = execute_uninstall(plan, backup_root=backup_root)

    assert (backup_dir / "manifest.json").is_file()
    assert (backup_dir / "report.md").is_file()
    manifest = json.loads((backup_dir / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["home"] == str(home.resolve())
    assert manifest["mode"] == "execute"
    assert manifest["owned"]
    assert manifest["rewritten"]
    assert manifest["shared"]
    assert not owned_dir.exists()
    assert shared_dir.exists()
    assert "export TEST_VAR=1" in (home / ".zshrc").read_text(encoding="utf-8")
    assert "settingZsh bootstrap" not in (home / ".zshrc").read_text(encoding="utf-8")
    assert not (home / "Documents" / "PowerShell" / "Microsoft.PowerShell_profile.ps1").exists()
    assert not (home / ".ssh" / "config").exists()
    assert not (home / ".ssh" / "config.d" / "10-common.conf").exists()
    report = (backup_dir / "report.md").read_text(encoding="utf-8")
    assert f"--home {home.resolve()}" in report
    assert f"--backup-root {backup_root.resolve()}" in report

    overwrite_backup_dir = restore_uninstall(home=home, backup_root=backup_root, backup_id=backup_dir.name)

    assert overwrite_backup_dir is not None
    assert (overwrite_backup_dir / ".zshrc").read_text(encoding="utf-8") == "export TEST_VAR=1\n"
    assert owned_dir.exists()
    assert (home / ".zshrc").read_text(encoding="utf-8") == original_zshrc
    assert (
        home / "Documents" / "PowerShell" / "Microsoft.PowerShell_profile.ps1"
    ).read_text(encoding="utf-8").startswith("# managed by chezmoi")
    assert (home / ".ssh" / "config").read_text(encoding="utf-8") == _template(
        "home/private_dot_ssh/config.tmpl"
    )
    assert (home / ".ssh" / "config.d" / "10-common.conf").read_text(encoding="utf-8") == _template(
        "home/private_dot_ssh/config.d/10-common.conf.tmpl"
    )


def test_is_settingzsh_powershell_bridge_detects_pure_bridge_and_rejects_mixed_content() -> None:
    bridge = (
        "# managed by chezmoi: PowerShell 7+ profile target\n"
        '$baselinePath = Join-Path $HOME ".config/settingzsh/powershell/public-baseline.ps1"\n'
        "if (Test-Path $baselinePath) {\n"
        "    . $baselinePath\n"
        "}\n"
    )
    mixed = "Set-StrictMode -Version Latest\n" + bridge

    assert is_settingzsh_powershell_bridge(bridge) is True
    assert is_settingzsh_powershell_bridge(mixed) is False
    assert strip_settingzsh_powershell_bridge(mixed) == "Set-StrictMode -Version Latest\n"


def test_restore_uninstall_rejects_invalid_backup_id_and_manifest_escape(tmp_path: Path) -> None:
    home = tmp_path / "home"
    backup_root = tmp_path / "backups"
    home.mkdir(parents=True, exist_ok=True)
    backup_root.mkdir(parents=True, exist_ok=True)

    try:
        restore_uninstall(home=home, backup_root=backup_root, backup_id="../evil")
    except ValueError as exc:
        assert "backup" in str(exc)
    else:
        raise AssertionError("restore should reject backup id traversal")

    backup_dir = backup_root / "20260406010101"
    backup_dir.mkdir(parents=True, exist_ok=True)
    (backup_dir / "manifest.json").write_text(
        json.dumps(
            {
                "home": str(home.resolve()),
                "owned": [],
                "rewritten": [
                    {
                        "path": str(tmp_path / "outside.txt"),
                        "backup": "rewritten/.zshrc",
                    }
                ],
            }
        ),
        encoding="utf-8",
    )
    _write(backup_dir / "rewritten" / ".zshrc", "outside\n")

    try:
        restore_uninstall(home=home, backup_root=backup_root, backup_id=backup_dir.name)
    except ValueError as exc:
        assert "home" in str(exc)
    else:
        raise AssertionError("restore should reject manifest targets outside home")


def test_restore_uninstall_snapshots_existing_target_before_overwrite(tmp_path: Path) -> None:
    home = tmp_path / "home"
    backup_root = tmp_path / "backups"
    (home / ".config" / "settingzsh").mkdir(parents=True, exist_ok=True)
    original_zshrc = (
        "export TEST_VAR=1\n"
        "# >>> settingZsh bootstrap >>>\n"
        '[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"\n'
        "# <<< settingZsh bootstrap <<<\n"
    )
    _write(home / ".zshrc", original_zshrc)

    plan = collect_uninstall_plan(home)
    backup_dir = execute_uninstall(plan, backup_root=backup_root)
    _write(home / ".zshrc", "post-uninstall change\n")

    overwrite_backup_dir = restore_uninstall(home=home, backup_root=backup_root, backup_id=backup_dir.name)

    assert overwrite_backup_dir is not None
    assert (overwrite_backup_dir / ".zshrc").read_text(encoding="utf-8") == "post-uninstall change\n"
    assert (home / ".zshrc").read_text(encoding="utf-8") == original_zshrc


def test_render_uninstall_report_includes_restore_command_with_explicit_paths(tmp_path: Path) -> None:
    home = (tmp_path / "home").resolve()
    backup_root = (tmp_path / "backups").resolve()
    plan = collect_uninstall_plan(home)

    report = render_uninstall_report(
        plan,
        mode="execute",
        backup_id="20260406010101",
        backup_root=backup_root,
    )

    assert f"--home {home}" in report
    assert f"--backup-root {backup_root}" in report
