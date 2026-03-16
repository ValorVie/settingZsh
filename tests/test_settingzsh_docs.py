from __future__ import annotations

from pathlib import Path


_PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_readme_mentions_bootstrap_doctor_migrate_and_private_repo() -> None:
    readme = (_PROJECT_ROOT / "README.md").read_text(encoding="utf-8")

    assert "chezmoi init --apply" in readme
    assert "fresh install" in readme
    assert "existing machine" in readme
    assert "bootstrap" in readme
    assert "adoption gate" in readme
    assert "preflight" in readme
    assert "adopt" in readme
    assert "doctor" in readme
    assert "migrate" in readme
    assert "legacy-import" in readme
    assert ".config/settingzsh/init.zsh" in readme
    assert "managed.d" in readme
    assert "custom private repo" in readme
    assert "examples/valor-ssh-key" in readme
    assert 'private_ssh_overlay_repo = ""' in readme
    assert "dot_config/settingzsh/powershell/" in readme
    assert "docs/adoption-guide.md" in readme
    assert "keepassxc-cli" in readme
    assert "gopass" in readme
    assert "SOPS + age" in readme
    assert "docs/secrets/sops-age.md" in readme
    assert "shared-keys" in readme
    assert "常見操作場景" in readme
    assert "故障排查" in readme
    assert "custom private repo 最小接線流程" in readme
    assert "preflight 結果怎麼看" in readme
    assert "開啟或關閉 editor feature" in readme


def test_architecture_doc_explains_dotfiles_chezmoi_and_project_layers() -> None:
    architecture = (_PROJECT_ROOT / "docs" / "architecture.md").read_text(
        encoding="utf-8"
    )

    assert "dotfiles" in architecture
    assert "chezmoi" in architecture
    assert "public baseline" in architecture
    assert "custom private repo" in architecture
    assert "doctor" in architecture
    assert "adoption gate" in architecture
    assert "modify_dot_zshrc" in architecture
    assert "run_*" in architecture
    assert "nvim / vim baseline" in architecture
    assert "SOPS + age" in architecture
    assert "shared-keys" in architecture
    assert "standard path" in architecture
    assert "custom managed path" in architecture


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


def test_adoption_and_secret_guides_exist_and_describe_scope() -> None:
    adoption = (_PROJECT_ROOT / "docs" / "adoption-guide.md").read_text(encoding="utf-8")
    keepassxc = (_PROJECT_ROOT / "docs" / "secrets" / "keepassxc-cli.md").read_text(
        encoding="utf-8"
    )
    gopass = (_PROJECT_ROOT / "docs" / "secrets" / "gopass.md").read_text(
        encoding="utf-8"
    )
    sops_age = (_PROJECT_ROOT / "docs" / "secrets" / "sops-age.md").read_text(
        encoding="utf-8"
    )

    assert "preflight" in adoption
    assert "legacy import" in adoption
    assert "needs_adopt" in adoption
    assert "desktop file secret" in keepassxc
    assert "runtime secret" in keepassxc
    assert "server file secret" in gopass
    assert "gopass init" in gopass
    assert "owner" in sops_age
    assert "recovery" in sops_age
    assert "updatekeys" in sops_age
    assert "rotate" in sops_age
