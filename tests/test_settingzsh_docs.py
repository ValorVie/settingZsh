from __future__ import annotations

from pathlib import Path


_PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_readme_mentions_bootstrap_doctor_and_migrate() -> None:
    readme = (_PROJECT_ROOT / "README.md").read_text(encoding="utf-8")

    assert "bootstrap" in readme
    assert "doctor" in readme
    assert "migrate" in readme
    assert ".config/settingzsh/init.zsh" in readme
    assert "managed.d" in readme
