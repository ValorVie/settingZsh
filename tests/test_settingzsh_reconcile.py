from __future__ import annotations

import subprocess
import sys
from pathlib import Path

# The write-path reconcile flow is retired. This file now covers the read-only
# validation and snapshot helpers that remain in `settingzsh.reconcile`.

# Ensure `lib/` is importable for pytest runs from repository root.
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_LIB_ROOT = _PROJECT_ROOT / "lib"
if str(_LIB_ROOT) not in sys.path:
    sys.path.insert(0, str(_LIB_ROOT))

from settingzsh.doctor import run_doctor
from settingzsh.reconcile import capture_file_snapshots
from settingzsh.reconcile import inspect_shell_validation
from settingzsh.reconcile import restore_file_snapshots
from settingzsh.reconcile import validate_shell


def test_doctor_uses_interactive_validation_by_default(
    tmp_path: Path, monkeypatch
) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    (home / ".zshrc").write_text("export TEST_VAR=1\n", encoding="utf-8")
    calls: list[Path] = []

    def fake_validator(target_home: Path):
        calls.append(target_home)
        return type(
            "ValidationStub",
            (),
            {
                "status": "ok",
                "issues": [],
                "syntax_stdout": "",
                "syntax_stderr": "",
                "interactive_stdout": "",
                "interactive_stderr": "",
            },
        )()

    monkeypatch.setattr("settingzsh.doctor.inspect_shell_validation", fake_validator)

    result = run_doctor(target_home=home)
    assert result.status == "ok"
    assert result.issues == []
    assert calls == [home]


def test_capture_file_snapshots_records_existing_and_missing_files(
    tmp_path: Path,
) -> None:
    existing = tmp_path / "existing.zsh"
    existing.write_text("export TEST_VAR=1\n", encoding="utf-8")
    missing = tmp_path / "missing.zsh"

    snapshots = capture_file_snapshots([existing, missing])

    assert snapshots[0].path == existing
    assert snapshots[0].existed is True
    assert snapshots[0].content == "export TEST_VAR=1\n"
    assert snapshots[1].path == missing
    assert snapshots[1].existed is False
    assert snapshots[1].content == ""


def test_restore_file_snapshots_restores_existing_content_and_removes_new_files(
    tmp_path: Path,
) -> None:
    root = tmp_path
    existing = root / "kept" / "existing.zsh"
    existing.parent.mkdir(parents=True, exist_ok=True)
    existing.write_text("original\n", encoding="utf-8")
    created = root / "pruned" / "created.zsh"

    snapshots = capture_file_snapshots([existing, created])
    existing.write_text("mutated\n", encoding="utf-8")
    created.parent.mkdir(parents=True, exist_ok=True)
    created.write_text("new content\n", encoding="utf-8")

    restore_file_snapshots(snapshots, root=root)

    assert existing.read_text(encoding="utf-8") == "original\n"
    assert not created.exists()
    assert not (root / "pruned").exists()
    assert (root / "kept").exists()


def test_inspect_shell_validation_runs_syntax_and_interactive_checks(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    (home / ".zshrc").write_text("export TEST_VAR=1\n", encoding="utf-8")

    calls: list[tuple[list[str], dict[str, str]]] = []

    def fake_run(
        cmd: list[str], *, check: bool, capture_output: bool, text: bool, env: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        assert check is False
        assert capture_output is True
        assert text is True
        calls.append((cmd, env))
        return subprocess.CompletedProcess(cmd, 0, "", "")

    result = inspect_shell_validation(home, runner=fake_run)

    assert result.status == "ok"
    assert calls[0][0] == ["zsh", "-n", str(home / ".zshrc")]
    assert calls[1][0] == ["zsh", "-i", "-c", "exit"]
    assert calls[1][1]["ZDOTDIR"] == str(home)
    assert calls[1][1]["HOME"] == str(home)


def test_validate_shell_raises_on_known_interactive_warning(tmp_path: Path) -> None:
    home = tmp_path / "home"
    home.mkdir(parents=True, exist_ok=True)
    (home / ".zshrc").write_text("export TEST_VAR=1\n", encoding="utf-8")

    def fake_run(
        cmd: list[str], *, check: bool, capture_output: bool, text: bool, env: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        if cmd[:2] == ["zsh", "-n"]:
            return subprocess.CompletedProcess(cmd, 0, "", "")
        return subprocess.CompletedProcess(cmd, 0, "", "gitstatus failed to initialize")

    try:
        validate_shell(home, runner=fake_run)
    except RuntimeError as exc:
        assert "interactive_shell_warning" in str(exc)
    else:
        raise AssertionError("validate_shell should fail on interactive warnings")
