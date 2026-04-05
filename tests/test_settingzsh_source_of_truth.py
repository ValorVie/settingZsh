from __future__ import annotations

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_legacy_shellgen_module_is_removed() -> None:
    assert not (PROJECT_ROOT / "lib" / "settingzsh" / "shellgen.py").exists()


def test_legacy_template_directory_is_removed() -> None:
    assert not (PROJECT_ROOT / "templates").exists()
