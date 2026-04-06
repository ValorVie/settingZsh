from __future__ import annotations

from pathlib import Path


_PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_readme_mentions_chezmoi_guardrails_and_retired_write_paths() -> None:
    readme = (_PROJECT_ROOT / "README.md").read_text(encoding="utf-8")

    assert "chezmoi init --apply" in readme
    assert "chezmoi update" in readme
    assert 'sh -c "$(curl -fsLS get.chezmoi.io)"' in readme
    assert "/usr/bin" in readme
    assert "https://github.com/ValorVie/settingZsh.git" in readme
    assert "--branch codex/settingzsh-chezmoi" in readme
    assert "唯一主控制面與主寫檔流程" in readme
    assert "fresh install" in readme
    assert "existing machine" in readme
    assert "bootstrap" in readme
    assert "adoption gate" in readme
    assert "preflight" in readme
    assert "adopt" in readme
    assert "doctor" in readme
    assert "legacy-import" in readme
    assert "settingzsh.cli` 的 `setup`、`update`、`migrate`、`reconcile` 已退役 / deprecated" in readme
    assert "退役 / deprecated write paths" in readme
    assert ".config/settingzsh/init.zsh" in readme
    assert "managed.d" in readme
    assert "custom private repo" in readme
    assert "examples/valor-ssh-key" in readme
    assert "[data.features]" in readme
    assert "[data.overlay]" in readme
    assert "private_ssh_overlay = true" in readme
    assert 'repo = ""' in readme
    assert 'profile = "auto"' in readme
    assert "SETTINGZSH_INSTALL_FONTS=false chezmoi init --apply" in readme
    assert "SETTINGZSH_INSTALL_FONTS=false chezmoi init --apply --branch codex/settingzsh-chezmoi" in readme
    assert "feature_editor" not in readme
    assert "install_fonts = true" not in readme
    assert "private_ssh_overlay_repo" not in readme
    assert "platform_profile" not in readme
    assert ".chezmoiroot" in readme
    assert "home/.chezmoi.toml.tmpl" in readme
    assert "home/.chezmoiexternal.toml.tmpl" in readme
    assert "dot_config/settingzsh/powershell/" in readme
    assert "docs/adoption-guide.md" in readme
    assert "docs/architecture-diagram.md" in readme
    assert "docs/fresh-install-inventory.md" in readme
    assert "docs/terminology.md" in readme
    assert "keepassxc-cli" in readme
    assert "gopass" in readme
    assert "SOPS + age" in readme
    assert "docs/secrets/sops-age.md" in readme
    assert "shared-keys" in readme
    assert "常見操作場景" in readme
    assert "故障排查" in readme
    assert "卸載與重置" in readme
    assert "scripts/uninstall-settingzsh.sh" in readme
    assert "docs/uninstall-guide.md" in readme
    assert "--dry-run" in readme
    assert "--execute" in readme
    assert "--restore <backup-id>" in readme
    assert "不會自動重新 init" in readme
    assert "exec zsh" in readme
    assert 'chsh -s /bin/zsh "$(whoami)"' in readme
    assert "LXC" in readme
    assert "container" in readme
    assert "server" in readme
    assert "不會替你改回去" in readme
    assert "custom private repo 最小接線流程" in readme
    assert "preflight 結果怎麼看" in readme
    assert "只走 `chezmoi`" in readme
    assert "開啟或關閉 editor feature" in readme
    assert "啟用 private SSH overlay" in readme
    assert "SETTINGZSH_INSTALL_FONTS=false chezmoi apply" in readme
    assert "~/.ssh/custom-paths" in readme


def test_uninstall_guide_documents_safe_reset_flow_and_login_shell_scope() -> None:
    guide = (_PROJECT_ROOT / "docs" / "uninstall-guide.md").read_text(encoding="utf-8")

    assert "什麼情況需要卸載 / 重置" in guide
    assert "scripts/uninstall-settingzsh.sh" in guide
    assert "--dry-run" in guide
    assert "--execute" in guide
    assert "--restore <backup-id>" in guide
    assert "專案專屬" in guide
    assert "局部改寫" in guide
    assert "共享路徑" in guide
    assert "人工確認" in guide
    assert "不會自動重新 init" in guide
    assert "不自動重新 init" in guide
    assert "二次 backup" in guide
    assert "exec zsh" in guide
    assert 'chsh -s /bin/zsh "$(whoami)"' in guide
    assert "LXC" in guide
    assert "container" in guide
    assert "不會替你改回去" in guide
    assert "~/.local/share/chezmoi" in guide
    assert "pure baseline" in guide
    assert "若含使用者自訂內容，預設不改" in guide


def test_private_repo_example_readme_uses_nested_overlay_schema() -> None:
    example_readme = (_PROJECT_ROOT / "examples" / "valor-ssh-key" / "README.md").read_text(
        encoding="utf-8"
    )

    assert "[data.features]\nprivate_ssh_overlay = true\n\n[data.overlay]\nrepo = \"git@github.com:<you>/<your-private-repo>.git\"\nprofile = \"auto\"" in example_readme
    assert "private_ssh_overlay_repo" not in example_readme
    assert "platform_profile" not in example_readme


def test_architecture_doc_explains_dotfiles_chezmoi_and_project_layers() -> None:
    architecture = (_PROJECT_ROOT / "docs" / "architecture.md").read_text(
        encoding="utf-8"
    )

    assert "來源目錄" in architecture
    assert "目標檔案" in architecture
    assert "terminology.md" in architecture
    assert "dotfiles" in architecture
    assert "chezmoi" in architecture
    assert "public baseline" in architecture
    assert "custom private repo" in architecture
    assert "doctor" in architecture
    assert "adoption gate" in architecture
    assert "legacy-import" in architecture
    assert "settingzsh.cli" in architecture
    assert "[data.features].editor" in architecture
    assert "[data.overlay].repo" in architecture
    assert "modify_dot_zshrc" in architecture
    assert ".chezmoiroot" in architecture
    assert "~/.local/share/chezmoi" in architecture
    assert "~/.config/chezmoi" in architecture
    assert "~/.config/settingzsh" in architecture
    assert "source repo" in architecture
    assert "persistent state" in architecture
    assert "runtime baseline" in architecture
    assert "run_*" in architecture
    assert "nvim / vim baseline" in architecture
    assert "SOPS + age" in architecture
    assert "shared-keys" in architecture
    assert "standard path" in architecture
    assert "custom managed path" in architecture
    assert ".chezmoiexternal.toml.tmpl" in architecture
    assert "run_onchange_after_40-install-private-ssh" in architecture
    assert "~/.ssh/custom-paths" in architecture
    assert "retired / deprecated write paths" in architecture
    assert "setup / update / migrate / reconcile" in architecture


def test_architecture_diagram_doc_exists_and_has_mermaid_views() -> None:
    diagram = (_PROJECT_ROOT / "docs" / "architecture-diagram.md").read_text(
        encoding="utf-8"
    )

    assert "```mermaid" in diagram
    assert "新機器首次安裝流程" in diagram
    assert "terminology.md" in diagram
    assert ".zshrc" in diagram
    assert "~/.local/share/chezmoi" in diagram
    assert "~/.config/chezmoi" in diagram
    assert "~/.config/settingzsh" in diagram
    assert "source repo / source state" in diagram
    assert "runtime baseline" in diagram
    assert "private_ssh_overlay" in diagram
    assert "~/.ssh/custom-paths" in diagram
    assert "settingzsh.cli guardrails" in diagram
    assert "退役 / deprecated write paths" in diagram
    assert "legacy-import" in diagram
    assert "setup" in diagram
    assert "update" in diagram
    assert "migrate" in diagram
    assert "reconcile" in diagram


def test_fresh_install_inventory_doc_lists_flow_targets_and_scripts() -> None:
    inventory = (_PROJECT_ROOT / "docs" / "fresh-install-inventory.md").read_text(
        encoding="utf-8"
    )

    assert "terminology.md" in inventory
    assert "寫入落地" in (_PROJECT_ROOT / "docs" / "terminology.md").read_text(encoding="utf-8")
    assert "基線設定" in inventory
    assert "新機器首次安裝流程" in inventory
    assert "baseline 更新同樣只走 `chezmoi update`" in inventory
    assert "settingzsh.cli" not in inventory
    assert "[data.features].editor" in inventory
    assert "[data.features].fonts" in inventory
    assert "[data.overlay].repo" in inventory
    assert "[data.overlay].profile" in inventory
    assert "feature_editor" not in inventory
    assert "install_fonts=true" not in inventory
    assert "private_ssh_overlay_repo" not in inventory
    assert "既有 `.zshrc`" not in inventory
    assert "~/.local/share/chezmoi" in inventory
    assert "~/.local/share/chezmoi/home" in inventory
    assert "~/.zshrc" in inventory
    assert "~/.config/settingzsh/init.zsh" in inventory
    assert "~/.local/share/zinit/zinit.git" in inventory
    assert "~/.ssh/custom-paths" in inventory
    assert "run_once_before_10-install-base-packages" in inventory
    assert "run_onchange_after_40-install-private-ssh" in inventory


def test_terminology_doc_exists_and_defines_maintenance_rule() -> None:
    terminology = (_PROJECT_ROOT / "docs" / "terminology.md").read_text(
        encoding="utf-8"
    )

    assert "統一維護點" in terminology
    assert "新增英文術語時，必須同步更新這份總表" in terminology
    assert "public baseline" in terminology
    assert "source state" in terminology
    assert "materialize" in terminology


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
    assert "[data.features]" in editor_guide
    assert "editor = true" in editor_guide
    assert "preflight" in editor_guide
    assert "adopt" in editor_guide
    assert "doctor" in editor_guide
    assert "feature_editor" not in editor_guide
    assert "migrate" not in editor_guide
    assert "reconcile" not in editor_guide
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
    assert "terminology.md" in adoption
    assert "legacy import" in adoption
    assert "needs_adopt" in adoption
    assert "退役 / deprecated write paths" in adoption
    assert "不要把它們當成 adoption 的下一步" in adoption
    assert "desktop file secret" in keepassxc
    assert "runtime secret" in keepassxc
    assert "server file secret" in gopass
    assert "gopass init" in gopass
    assert "owner" in sops_age
    assert "recovery" in sops_age
    assert "updatekeys" in sops_age
    assert "rotate" in sops_age
