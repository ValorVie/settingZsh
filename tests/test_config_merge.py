"""配置檔合併引擎 (config_merge) 的單元測試。

測試涵蓋：
  1. 全新安裝（目標不存在）
  2. 全新安裝（目標為空檔）
  3. 已有標記時更新管理區段
  4. 首次升級（無標記）
  5. vim set 值衝突偵測
  6. 完全重複行移除
  7. dry-run 模式不寫入檔案
  8. 缺少結束標記（視為無標記 → 首次升級路徑）
  9. 多個管理區段互不影響
  10. CLI 參數解析：缺少必要參數回傳錯誤
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

# 確保專案根目錄在 sys.path 中，以便 import lib.config_merge
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

from lib.config_merge import (
    EXIT_ERROR,
    EXIT_FRESH_INSTALL,
    EXIT_SUCCESS,
    MergeResult,
    _dedup_lines,
    _find_managed_section,
    _managed_begin,
    _managed_end,
    _user_begin,
    _user_end,
    build_parser,
    main,
    merge,
    path_add_section,
    path_first_upgrade,
    path_fresh_install,
    path_update_managed,
)


# ---------------------------------------------------------------------------
# 輔助函式
# ---------------------------------------------------------------------------


def _write(path: Path, content: str) -> None:
    """寫入測試用檔案。"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _read(path: Path) -> str:
    """讀取測試用檔案。"""
    return path.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# 1. 全新安裝 — 目標不存在
# ---------------------------------------------------------------------------


class TestFreshInstallTargetMissing:
    """路徑 1：目標檔案不存在時，應建立含標記 + 模板 + 空使用者區段的檔案。"""

    def test_creates_file_with_markers_and_exit_code_2(self, tmp_path: Path) -> None:
        """目標不存在時應產生 exit_code=2 並寫入完整結構。"""
        target = tmp_path / "subdir" / ".zshrc"  # 父目錄也不存在
        template = tmp_path / "tpl_zshrc"
        _write(template, "export PATH=/usr/local/bin:$PATH\n")

        result = merge(target, template, "zsh-base", "zsh")

        # 驗證結束碼
        assert result.exit_code == EXIT_FRESH_INSTALL

        # 驗證檔案已建立
        assert target.exists()
        content = _read(target)

        # 驗證管理區段標記
        assert _managed_begin("zsh-base", "zsh") in content
        assert _managed_end("zsh-base", "zsh") in content

        # 驗證使用者區段標記
        assert _user_begin("zsh") in content
        assert _user_end("zsh") in content

        # 驗證模板內容在管理區段內
        assert "export PATH=/usr/local/bin:$PATH" in content

    def test_vim_type_uses_double_quote_markers(self, tmp_path: Path) -> None:
        """vim 類型應使用雙引號作為註解字元。"""
        target = tmp_path / ".vimrc"
        template = tmp_path / "tpl_vimrc"
        _write(template, "set number\n")

        result = merge(target, template, "vimrc", "vim")

        assert result.exit_code == EXIT_FRESH_INSTALL
        content = _read(target)
        # vim 的標記以 " 開頭
        assert '" === settingZsh:managed:vimrc:begin ===' in content
        assert '" === settingZsh:managed:vimrc:end ===' in content


# ---------------------------------------------------------------------------
# 2. 全新安裝 — 目標為空檔
# ---------------------------------------------------------------------------


class TestFreshInstallTargetEmpty:
    """路徑 1：目標檔案存在但內容為空（或僅空白），與不存在等效。"""

    def test_empty_file_treated_as_fresh_install(self, tmp_path: Path) -> None:
        """空檔案應走全新安裝路徑。"""
        target = tmp_path / ".zshrc"
        _write(target, "")
        template = tmp_path / "tpl"
        _write(template, "alias ll='ls -la'\n")

        result = merge(target, template, "zsh-alias", "zsh")

        assert result.exit_code == EXIT_FRESH_INSTALL
        content = _read(target)
        assert "alias ll='ls -la'" in content

    def test_whitespace_only_treated_as_fresh_install(self, tmp_path: Path) -> None:
        """僅含空白字元的檔案也應走全新安裝路徑。"""
        target = tmp_path / ".zshrc"
        _write(target, "   \n\n  \n")
        template = tmp_path / "tpl"
        _write(template, "export FOO=bar\n")

        result = merge(target, template, "zsh-env", "zsh")

        assert result.exit_code == EXIT_FRESH_INSTALL


# ---------------------------------------------------------------------------
# 3. 已有標記時更新管理區段
# ---------------------------------------------------------------------------


class TestUpdateManagedSection:
    """路徑 2：目標已有管理標記，僅替換管理區段，保留使用者區段與其他內容。"""

    def test_replace_managed_section_preserves_user_section(
        self, tmp_path: Path
    ) -> None:
        """更新時應替換管理區段內容，保留使用者區段不變。"""
        section_id = "zsh-base"
        ft = "zsh"
        mb = _managed_begin(section_id, ft)
        me = _managed_end(section_id, ft)
        ub = _user_begin(ft)
        ue = _user_end(ft)

        old_content = "\n".join(
            [
                mb,
                "export OLD_VAR=old",
                me,
                "",
                ub,
                "my_custom_alias='hello'",
                ue,
            ]
        ) + "\n"

        target = tmp_path / ".zshrc"
        _write(target, old_content)
        template = tmp_path / "tpl"
        _write(template, "export NEW_VAR=new\n")

        result = merge(target, template, section_id, ft)

        assert result.exit_code == EXIT_SUCCESS
        content = _read(target)

        # 舊模板內容應被替換
        assert "OLD_VAR" not in content
        # 新模板內容應出現
        assert "export NEW_VAR=new" in content
        # 使用者自訂內容應保留
        assert "my_custom_alias='hello'" in content

    def test_content_outside_markers_preserved(self, tmp_path: Path) -> None:
        """管理區段外的非標記內容應保持不變。"""
        section_id = "zsh-base"
        ft = "zsh"
        mb = _managed_begin(section_id, ft)
        me = _managed_end(section_id, ft)

        old_content = "\n".join(
            [
                "# 檔案頂端的自訂內容",
                mb,
                "export OLD=1",
                me,
                "# 檔案底端的自訂內容",
            ]
        ) + "\n"

        target = tmp_path / ".zshrc"
        _write(target, old_content)
        template = tmp_path / "tpl"
        _write(template, "export NEW=2\n")

        merge(target, template, section_id, ft)
        content = _read(target)

        assert "# 檔案頂端的自訂內容" in content
        assert "# 檔案底端的自訂內容" in content


# ---------------------------------------------------------------------------
# 4. 首次升級（無標記）
# ---------------------------------------------------------------------------


class TestFirstUpgrade:
    """路徑 3：目標有內容但無標記 → 備份 + 去重 + 包裝標記。"""

    def test_backup_created_and_markers_added(self, tmp_path: Path) -> None:
        """首次升級應建立備份檔並在輸出中加入標記。"""
        target = tmp_path / ".zshrc"
        _write(target, "export PATH=/usr/local/bin:$PATH\nmy_alias='foo'\n")
        template = tmp_path / "tpl"
        _write(template, "export PATH=/usr/local/bin:$PATH\n")

        result = merge(target, template, "zsh-base", "zsh")

        assert result.exit_code == EXIT_SUCCESS
        # 應建立備份檔
        assert result.backup_path is not None
        assert Path(result.backup_path).exists()

        content = _read(target)
        # 應包含管理區段
        assert _managed_begin("zsh-base", "zsh") in content
        assert _managed_end("zsh-base", "zsh") in content
        # 應包含使用者區段
        assert _user_begin("zsh") in content
        assert _user_end("zsh") in content

    def test_duplicate_lines_removed_from_user_section(self, tmp_path: Path) -> None:
        """與模板完全重複的使用者行應被移除並記錄。"""
        target = tmp_path / ".zshrc"
        _write(target, "export PATH=/usr/local/bin:$PATH\nmy_custom='bar'\n")
        template = tmp_path / "tpl"
        _write(template, "export PATH=/usr/local/bin:$PATH\n")

        result = merge(target, template, "zsh-base", "zsh")

        # 重複行應記錄
        assert len(result.removed_duplicates) == 1
        assert "export PATH=/usr/local/bin:$PATH" in result.removed_duplicates[0]

        # 使用者自訂行應保留在使用者區段
        content = _read(target)
        lines = content.splitlines()
        user_start = lines.index(_user_begin("zsh"))
        user_end = lines.index(_user_end("zsh"))
        user_section = "\n".join(lines[user_start:user_end + 1])
        assert "my_custom='bar'" in user_section


# ---------------------------------------------------------------------------
# 5. vim set 值衝突偵測
# ---------------------------------------------------------------------------


class TestValueConflict:
    """vim set 指令衝突偵測：使用者版本保留，衝突列入結果。"""

    def test_vim_set_conflict_detected_and_user_kept(self, tmp_path: Path) -> None:
        """使用者 set tabstop=2 vs 模板 set tabstop=4 → 使用者保留、衝突記錄。"""
        target = tmp_path / ".vimrc"
        _write(target, "set tabstop=2\nset shiftwidth=2\n")
        template = tmp_path / "tpl"
        _write(template, "set tabstop=4\nset number\n")

        result = merge(target, template, "vimrc", "vim")

        # 應偵測到衝突
        assert len(result.value_conflicts) >= 1
        conflict_keys = [pair[0] for pair in result.value_conflicts]
        # 使用者的 set tabstop=2 應出現在衝突的使用者端
        assert any("tabstop=2" in k for k in conflict_keys)

        # 使用者的值應保留在使用者區段
        content = _read(target)
        lines = content.splitlines()
        ub = _user_begin("vim")
        ue = _user_end("vim")
        user_start = lines.index(ub)
        user_end = lines.index(ue)
        user_block = "\n".join(lines[user_start:user_end + 1])
        assert "set tabstop=2" in user_block

    def test_non_conflicting_vim_set_not_flagged(self, tmp_path: Path) -> None:
        """不衝突的 vim set 不應被標記。"""
        target = tmp_path / ".vimrc"
        _write(target, "set cursorline\n")
        template = tmp_path / "tpl"
        _write(template, "set number\n")

        result = merge(target, template, "vimrc", "vim")

        assert len(result.value_conflicts) == 0


# ---------------------------------------------------------------------------
# 6. 完全重複行移除
# ---------------------------------------------------------------------------


class TestExactDuplicateRemoval:
    """完全相同的行應從使用者區段中移除。"""

    def test_exact_duplicates_removed(self, tmp_path: Path) -> None:
        """使用者行與模板行完全相同（正規化後）時應移除。"""
        user_lines = [
            "export PATH=/usr/local/bin:$PATH",
            "  export PATH=/usr/local/bin:$PATH  ",  # 含額外空白，正規化後相同
            "my_own_setting=true",
        ]
        template_lines = [
            "export PATH=/usr/local/bin:$PATH",
        ]

        removed, kept, conflicts = _dedup_lines(user_lines, template_lines, "zsh")

        assert len(removed) == 2  # 兩行正規化後皆重複
        # 自訂行應保留
        kept_stripped = [ln.strip() for ln in kept if ln.strip()]
        assert "my_own_setting=true" in kept_stripped

    def test_comments_and_empty_lines_always_kept(self, tmp_path: Path) -> None:
        """註解行與空行不參與去重比較，一律保留。"""
        user_lines = [
            "# 這是使用者的註解",
            "",
            "export FOO=bar",
        ]
        template_lines = [
            "export FOO=bar",
        ]

        removed, kept, conflicts = _dedup_lines(user_lines, template_lines, "zsh")

        assert len(removed) == 1  # 僅 export FOO=bar 被去重
        # 註解和空行保留
        assert "# 這是使用者的註解" in kept
        assert "" in kept


# ---------------------------------------------------------------------------
# 7. dry-run 模式
# ---------------------------------------------------------------------------


class TestDryRunMode:
    """dry-run 模式不應寫入任何檔案，但摘要資訊仍應產生。"""

    def test_fresh_install_dry_run_no_file_written(self, tmp_path: Path) -> None:
        """dry-run 在全新安裝時不應建立目標檔案。"""
        target = tmp_path / ".zshrc"
        template = tmp_path / "tpl"
        _write(template, "export X=1\n")

        result = merge(target, template, "zsh-base", "zsh", dry_run=True)

        assert result.exit_code == EXIT_FRESH_INSTALL
        # 目標檔案不應被建立
        assert not target.exists()

    def test_first_upgrade_dry_run_no_backup_created(self, tmp_path: Path) -> None:
        """dry-run 在首次升級時不應建立備份檔，但 backup_path 仍有值。"""
        target = tmp_path / ".zshrc"
        _write(target, "some existing content\n")
        template = tmp_path / "tpl"
        _write(template, "export X=1\n")

        original_content = _read(target)
        result = merge(target, template, "zsh-base", "zsh", dry_run=True)

        assert result.exit_code == EXIT_SUCCESS
        # backup_path 有值（供摘要顯示）
        assert result.backup_path is not None
        # 但備份檔實際不存在
        assert not Path(result.backup_path).exists()
        # 原始檔案內容不變
        assert _read(target) == original_content

    def test_update_managed_dry_run_no_file_change(self, tmp_path: Path) -> None:
        """dry-run 在更新管理區段時不應修改目標檔案。"""
        section_id = "zsh-base"
        ft = "zsh"
        mb = _managed_begin(section_id, ft)
        me = _managed_end(section_id, ft)

        old_content = "\n".join([mb, "export OLD=1", me]) + "\n"
        target = tmp_path / ".zshrc"
        _write(target, old_content)
        template = tmp_path / "tpl"
        _write(template, "export NEW=2\n")

        merge(target, template, section_id, ft, dry_run=True)

        # 檔案內容不應改變
        assert _read(target) == old_content


# ---------------------------------------------------------------------------
# 8. 缺少結束標記 → 視為無標記（首次升級路徑）
# ---------------------------------------------------------------------------


class TestMissingEndMarker:
    """僅有開始標記但缺少結束標記的處理。

    因為檔案含有 settingZsh 標記（即使不完整），走路徑 4（新增區段），
    而非路徑 3（首次升級）。
    """

    def test_missing_end_marker_adds_section(self, tmp_path: Path) -> None:
        """缺少結束標記時，因偵測到標記存在，走路徑 4 新增完整區段。"""
        section_id = "zsh-base"
        ft = "zsh"
        mb = _managed_begin(section_id, ft)

        # 只有開始標記，沒有結束標記
        broken_content = "\n".join(
            [
                mb,
                "export OLD=1",
                "user_custom_line='keep_me'",
            ]
        ) + "\n"

        target = tmp_path / ".zshrc"
        _write(target, broken_content)
        template = tmp_path / "tpl"
        _write(template, "export NEW=2\n")

        result = merge(target, template, section_id, ft)

        assert result.exit_code == EXIT_SUCCESS

        # 輸出應包含完整的新管理區段
        content = _read(target)
        assert _managed_begin(section_id, ft) in content
        assert _managed_end(section_id, ft) in content


# ---------------------------------------------------------------------------
# 9. 多個管理區段互不影響
# ---------------------------------------------------------------------------


class TestMultipleManagedSections:
    """更新一個管理區段不應影響另一個管理區段的內容。"""

    def test_updating_one_section_preserves_another(self, tmp_path: Path) -> None:
        """更新 section-a 時 section-b 的內容應完整保留。"""
        ft = "zsh"
        mb_a = _managed_begin("section-a", ft)
        me_a = _managed_end("section-a", ft)
        mb_b = _managed_begin("section-b", ft)
        me_b = _managed_end("section-b", ft)

        existing = "\n".join(
            [
                mb_a,
                "export A_OLD=1",
                me_a,
                "",
                mb_b,
                "export B_KEEP=999",
                me_b,
            ]
        ) + "\n"

        target = tmp_path / ".zshrc"
        _write(target, existing)

        template_a = tmp_path / "tpl_a"
        _write(template_a, "export A_NEW=2\n")

        # 只更新 section-a
        result = merge(target, template_a, "section-a", ft)

        assert result.exit_code == EXIT_SUCCESS
        content = _read(target)

        # section-a 已更新
        assert "A_OLD" not in content
        assert "export A_NEW=2" in content

        # section-b 保持不變
        assert "export B_KEEP=999" in content
        assert mb_b in content
        assert me_b in content


# ---------------------------------------------------------------------------
# 10. CLI 參數解析：缺少必要參數
# ---------------------------------------------------------------------------


class TestCLIArgumentParsing:
    """CLI 參數解析：缺少必要參數應回傳錯誤。"""

    def test_missing_required_args_exits_with_error(self) -> None:
        """未提供 --target 等必要參數時，argparse 應拋出 SystemExit(2)。"""
        with pytest.raises(SystemExit) as exc_info:
            # 不提供任何參數
            main([])
        # argparse 在缺少必要參數時以 exit code 2 結束
        assert exc_info.value.code == 2

    def test_missing_target_exits_with_error(self) -> None:
        """僅提供部分參數時也應失敗。"""
        with pytest.raises(SystemExit) as exc_info:
            main(["--template", "foo", "--section", "bar", "--type", "zsh"])
        assert exc_info.value.code == 2

    def test_invalid_type_exits_with_error(self) -> None:
        """--type 傳入不支援的值應失敗。"""
        with pytest.raises(SystemExit) as exc_info:
            main([
                "--target", "/tmp/x",
                "--template", "/tmp/y",
                "--section", "s",
                "--type", "invalid_type",
            ])
        assert exc_info.value.code == 2

    def test_valid_args_with_missing_template_returns_error(
        self, tmp_path: Path
    ) -> None:
        """參數格式正確但模板檔案不存在時，應回傳 EXIT_ERROR (1)。"""
        target = tmp_path / ".zshrc"
        nonexistent_template = tmp_path / "no_such_template"

        exit_code = main([
            "--target", str(target),
            "--template", str(nonexistent_template),
            "--section", "zsh-base",
            "--type", "zsh",
        ])

        assert exit_code == EXIT_ERROR


# ---------------------------------------------------------------------------
# 補充：merge() 函式模板不存在
# ---------------------------------------------------------------------------


class TestTemplateNotFound:
    """模板檔案不存在時 merge() 應回傳 EXIT_ERROR。"""

    def test_merge_returns_error_for_missing_template(self, tmp_path: Path) -> None:
        target = tmp_path / ".zshrc"
        nonexistent = tmp_path / "no_template"

        result = merge(target, nonexistent, "zsh-base", "zsh")

        assert result.exit_code == EXIT_ERROR


# ---------------------------------------------------------------------------
# 補充：_find_managed_section 內部函式
# ---------------------------------------------------------------------------


class TestFindManagedSection:
    """直接測試 _find_managed_section 的邊界情況。"""

    def test_returns_none_when_no_markers(self) -> None:
        """無標記行時回傳 None。"""
        lines = ["export A=1", "export B=2"]
        assert _find_managed_section(lines, "test", "zsh") is None

    def test_returns_none_when_only_begin(self) -> None:
        """僅有 begin 標記時回傳 None。"""
        mb = _managed_begin("test", "zsh")
        lines = [mb, "export A=1"]
        assert _find_managed_section(lines, "test", "zsh") is None

    def test_returns_correct_span(self) -> None:
        """完整標記對應正確回傳起止索引。"""
        mb = _managed_begin("test", "zsh")
        me = _managed_end("test", "zsh")
        lines = ["# before", mb, "content", me, "# after"]
        span = _find_managed_section(lines, "test", "zsh")
        assert span == (1, 3)


# ---------------------------------------------------------------------------
# 11. 路徑 4：新增區段至已有標記的檔案
# ---------------------------------------------------------------------------


class TestAddSectionToExistingMarkedFile:
    """路徑 4：檔案已有其他 settingZsh 標記，新增缺少的 section。"""

    def test_add_new_section_before_user_block(self, tmp_path: Path) -> None:
        """已有 editor 標記時，新增 zsh-base 應插入於 user 區段前。"""
        ft = "zsh"
        mb_e = _managed_begin("editor", ft)
        me_e = _managed_end("editor", ft)
        ub = _user_begin(ft)
        ue = _user_end(ft)

        existing = "\n".join([
            mb_e,
            "# editor content",
            me_e,
            "",
            ub,
            "my_custom='keep'",
            ue,
        ]) + "\n"

        target = tmp_path / ".zshrc"
        _write(target, existing)
        template = tmp_path / "tpl_zsh"
        _write(template, "export PATH=$HOME/.local/bin:$PATH\n")

        result = merge(target, template, "zsh-base", ft)

        assert result.exit_code == EXIT_SUCCESS
        content = _read(target)

        # 新的 zsh-base 管理區段應存在
        assert _managed_begin("zsh-base", ft) in content
        assert _managed_end("zsh-base", ft) in content
        # 原有的 editor 管理區段應保留
        assert mb_e in content
        assert me_e in content
        # 使用者區段應保留
        assert "my_custom='keep'" in content

        # 驗證順序：zsh-base 應在 user 區段之前
        lines = content.splitlines()
        idx_zsh_base_end = lines.index(_managed_end("zsh-base", ft))
        idx_user_begin = lines.index(ub)
        assert idx_zsh_base_end < idx_user_begin

    def test_add_section_no_duplicate_user_markers(self, tmp_path: Path) -> None:
        """新增區段後不應產生重複的 user:begin/end 標記。"""
        ft = "zsh"
        mb_e = _managed_begin("editor", ft)
        me_e = _managed_end("editor", ft)
        ub = _user_begin(ft)
        ue = _user_end(ft)

        existing = "\n".join([
            mb_e,
            "# editor",
            me_e,
            "",
            ub,
            ue,
        ]) + "\n"

        target = tmp_path / ".zshrc"
        _write(target, existing)
        template = tmp_path / "tpl"
        _write(template, "export X=1\n")

        merge(target, template, "zsh-base", ft)
        content = _read(target)

        assert content.count(_user_begin(ft)) == 1
        assert content.count(_user_end(ft)) == 1

    def test_repeated_merge_is_idempotent(self, tmp_path: Path) -> None:
        """重複執行相同的合併不應改變檔案結構。"""
        ft = "zsh"
        target = tmp_path / ".zshrc"
        tpl_editor = tmp_path / "tpl_editor"
        tpl_zsh = tmp_path / "tpl_zsh"
        _write(tpl_editor, "# editor config\n")
        _write(tpl_zsh, "export PATH=$PATH\n")

        # 第一輪：全新安裝 editor，再新增 zsh-base
        merge(target, tpl_editor, "editor", ft)
        merge(target, tpl_zsh, "zsh-base", ft)
        content_after_first = _read(target)

        # 第二輪：重複執行（應走路徑 2 — 更新已有標記）
        merge(target, tpl_editor, "editor", ft)
        merge(target, tpl_zsh, "zsh-base", ft)
        content_after_second = _read(target)

        assert content_after_first == content_after_second

    def test_three_sections_all_preserved(self, tmp_path: Path) -> None:
        """三個 section 依序合併後都應完整保留。"""
        ft = "zsh"
        target = tmp_path / ".zshrc"
        tpl_a = tmp_path / "tpl_a"
        tpl_b = tmp_path / "tpl_b"
        tpl_c = tmp_path / "tpl_c"
        _write(tpl_a, "export A=1\n")
        _write(tpl_b, "export B=2\n")
        _write(tpl_c, "export C=3\n")

        merge(target, tpl_a, "section-a", ft)
        merge(target, tpl_b, "section-b", ft)
        merge(target, tpl_c, "section-c", ft)

        content = _read(target)
        for sid in ("section-a", "section-b", "section-c"):
            assert _managed_begin(sid, ft) in content
            assert _managed_end(sid, ft) in content
        assert "export A=1" in content
        assert "export B=2" in content
        assert "export C=3" in content
        # 只有一個 user 區段
        assert content.count(_user_begin(ft)) == 1
        assert content.count(_user_end(ft)) == 1
