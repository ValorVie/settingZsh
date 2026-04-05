from __future__ import annotations

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_chezmoi_toml_uses_nested_features_and_overlay() -> None:
    content = (PROJECT_ROOT / "home" / ".chezmoi.toml.tmpl").read_text(
        encoding="utf-8"
    )

    assert "[data.features]" in content
    assert "[data.overlay]" in content
    assert "editor = false" in content
    assert "fonts = true" in content
    assert "private_ssh_overlay = false" in content
    assert 'repo = ""' in content
    assert 'profile = "auto"' in content
    assert "feature_editor" not in content
    assert "install_fonts" not in content
    assert "private_ssh_overlay_repo" not in content


def test_artifact_schema_contains_linux_x86_64_and_arm64_pairs() -> None:
    content = (PROJECT_ROOT / "home" / ".chezmoidata" / "artifacts.yaml").read_text(
        encoding="utf-8"
    )

    for tool in ("ripgrep", "fd", "neovim", "lazygit"):
        assert f"{tool}:" in content
    assert "linux:" in content
    assert "x86_64:" in content
    assert "arm64:" in content


def test_defaults_schema_exposes_nested_features_and_overlay_defaults() -> None:
    content = (PROJECT_ROOT / "home" / ".chezmoidata" / "defaults.yaml").read_text(
        encoding="utf-8"
    )

    assert "features:" in content
    assert "editor: false" in content
    assert "fonts: true" in content
    assert "private_ssh_overlay: false" in content
    assert "overlay:" in content
    assert 'repo: ""' in content
    assert 'profile: "auto"' in content


def test_legacy_common_data_file_is_removed() -> None:
    assert not (PROJECT_ROOT / "home" / ".chezmoidata" / "common.yaml").exists()
