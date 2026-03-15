from __future__ import annotations

from pathlib import Path


_PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_readme_mentions_bootstrap_doctor_migrate_and_private_repo() -> None:
    readme = (_PROJECT_ROOT / "README.md").read_text(encoding="utf-8")

    assert "chezmoi init --apply" in readme
    assert "bootstrap" in readme
    assert "doctor" in readme
    assert "migrate" in readme
    assert ".config/settingzsh/init.zsh" in readme
    assert "managed.d" in readme
    assert "custom private repo" in readme
    assert "examples/valor-ssh-key" in readme
    assert 'private_ssh_overlay_repo = ""' in readme
    assert "dot_config/settingzsh/powershell/" in readme


def test_architecture_doc_explains_dotfiles_chezmoi_and_project_layers() -> None:
    architecture = (_PROJECT_ROOT / "docs" / "architecture.md").read_text(
        encoding="utf-8"
    )

    assert "dotfiles" in architecture
    assert "chezmoi" in architecture
    assert "public baseline" in architecture
    assert "custom private repo" in architecture
    assert "doctor" in architecture
    assert "run_*" in architecture
    assert "nvim / vim baseline" in architecture


def test_legacy_docs_are_clearly_marked_and_redirect_to_current_flow() -> None:
    legacy_plan = (_PROJECT_ROOT / "docs" / "plan.md").read_text(encoding="utf-8")
    legacy_windows = (_PROJECT_ROOT / "Windows-Powershell" / "README.md").read_text(
        encoding="utf-8"
    )
    editor_guide = (_PROJECT_ROOT / "docs" / "editor-guide.md").read_text(
        encoding="utf-8"
    )

    assert "歷史文件" in legacy_plan
    assert "pre-chezmoi" in legacy_plan
    assert "source state" in legacy_windows
    assert "chezmoi init --apply" in legacy_windows
    assert "feature_editor = true" in editor_guide
    assert "Windows 目前只部署 Neovim" in editor_guide
