#!/usr/bin/env python3
"""配置檔合併引擎 — 將模板區段合併至目標配置檔，保留使用者自訂內容。

支援 zsh (#) 與 vim (") 兩種註解格式，提供三種合併路徑：
  1. 全新安裝（目標不存在）
  2. 已有標記（僅替換管理區段）
  3. 首次升級（備份 + 去重 + 包裝標記）

用法：
  python3 config_merge.py --target ~/.zshrc --template tpl/zshrc --section zsh-base --type zsh
  python3 config_merge.py --target ~/.vimrc --template tpl/vimrc --section vimrc --type vim --dry-run
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# 常數
# ---------------------------------------------------------------------------

MARKER_PREFIX = "settingZsh"

# 結束碼
EXIT_SUCCESS = 0
EXIT_ERROR = 1
EXIT_FRESH_INSTALL = 2

# ANSI 色彩
_BOLD = "\033[1m"
_YELLOW = "\033[33m"
_RED = "\033[31m"
_GREEN = "\033[32m"
_CYAN = "\033[36m"
_RESET = "\033[0m"


# ---------------------------------------------------------------------------
# 資料模型
# ---------------------------------------------------------------------------


@dataclass
class MergeResult:
    """合併結果，用於輸出摘要。"""

    section_id: str = ""
    filename: str = ""
    removed_duplicates: list[str] = field(default_factory=list)
    value_conflicts: list[tuple[str, str]] = field(default_factory=list)
    kept_custom: list[str] = field(default_factory=list)
    backup_path: str | None = None
    exit_code: int = EXIT_SUCCESS


# ---------------------------------------------------------------------------
# 標記工具
# ---------------------------------------------------------------------------


def _comment_char(file_type: str) -> str:
    """根據檔案類型回傳註解字元。"""
    return '"' if file_type == "vim" else "#"


def _managed_begin(section_id: str, file_type: str) -> str:
    cc = _comment_char(file_type)
    return f"{cc} === {MARKER_PREFIX}:managed:{section_id}:begin ==="


def _managed_end(section_id: str, file_type: str) -> str:
    cc = _comment_char(file_type)
    return f"{cc} === {MARKER_PREFIX}:managed:{section_id}:end ==="


def _user_begin(file_type: str) -> str:
    cc = _comment_char(file_type)
    return f"{cc} === {MARKER_PREFIX}:user:begin ==="


def _user_end(file_type: str) -> str:
    cc = _comment_char(file_type)
    return f"{cc} === {MARKER_PREFIX}:user:end ==="


def _is_marker_line(line: str) -> bool:
    """判斷是否為任何 settingZsh 標記行。"""
    stripped = line.strip()
    # 支援 # 或 " 開頭的標記
    for cc in ("#", '"'):
        if stripped.startswith(f"{cc} === {MARKER_PREFIX}:") and stripped.endswith(" ==="):
            return True
    return False


# ---------------------------------------------------------------------------
# 正規化與去重
# ---------------------------------------------------------------------------


def _normalize(line: str) -> str:
    """正規化一行：去除首尾空白，壓縮連續空白。"""
    return re.sub(r"\s+", " ", line.strip())


def _is_comment_or_empty(line: str, file_type: str) -> bool:
    """判斷是否為純註解行或空行（不參與比較）。"""
    stripped = line.strip()
    if not stripped:
        return True
    cc = _comment_char(file_type)
    return stripped.startswith(cc)


def _vim_set_key(line: str) -> str | None:
    """從 vim set 指令中擷取鍵名。

    例如 ``set tabstop=4`` → ``tabstop``，``set number`` → ``number``。
    回傳 None 表示非 set 指令。
    """
    m = re.match(r"^\s*set\s+(no)?(\w+)", line)
    if m:
        return m.group(2)
    return None


def _dedup_lines(
    user_lines: list[str],
    template_lines: list[str],
    file_type: str,
) -> tuple[list[str], list[str], list[tuple[str, str]]]:
    """比較使用者行與模板行，分類為：重複 / 衝突 / 自訂。

    回傳 (removed_duplicates, kept_custom, value_conflicts)。
    其中 kept_custom 包含保留的使用者行（含衝突行）。
    """
    # 建立模板正規化集合
    tpl_normalized: set[str] = set()
    tpl_vim_keys: dict[str, str] = {}  # key → 原始行

    for tl in template_lines:
        if _is_comment_or_empty(tl, file_type):
            continue
        norm = _normalize(tl)
        tpl_normalized.add(norm)
        if file_type == "vim":
            vk = _vim_set_key(norm)
            if vk is not None:
                tpl_vim_keys[vk] = tl.strip()

    removed: list[str] = []
    conflicts: list[tuple[str, str]] = []
    kept: list[str] = []

    for ul in user_lines:
        # 保留註解行與空行
        if _is_comment_or_empty(ul, file_type):
            kept.append(ul)
            continue

        norm_u = _normalize(ul)

        # 完全重複
        if norm_u in tpl_normalized:
            removed.append(ul.rstrip())
            continue

        # vim set 指令語義比較
        if file_type == "vim":
            vk = _vim_set_key(norm_u)
            if vk is not None and vk in tpl_vim_keys:
                conflicts.append((ul.strip(), tpl_vim_keys[vk]))
                kept.append(ul)
                continue

        # 使用者獨有
        kept.append(ul)

    return removed, kept, conflicts


# ---------------------------------------------------------------------------
# 檔案讀寫
# ---------------------------------------------------------------------------


def _read_file(path: Path) -> str | None:
    """讀取檔案內容，檔案不存在時回傳 None。"""
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return None


def _write_file(path: Path, content: str) -> None:
    """寫入檔案，自動建立父目錄。"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _backup_file(path: Path) -> str:
    """備份檔案，回傳備份路徑。格式：<path>.bak.YYYYMMDD-HHMMSS"""
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    bak = path.with_name(f"{path.name}.bak.{ts}")
    bak.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")
    return str(bak)


# ---------------------------------------------------------------------------
# 標記搜尋
# ---------------------------------------------------------------------------


def _find_managed_section(
    lines: list[str], section_id: str, file_type: str
) -> tuple[int, int] | None:
    """在行列表中尋找指定管理區段的 begin/end 行號（含標記行本身）。

    回傳 (begin_idx, end_idx) 或 None（找不到完整配對）。
    """
    begin_marker = _managed_begin(section_id, file_type)
    end_marker = _managed_end(section_id, file_type)

    begin_idx: int | None = None
    end_idx: int | None = None

    for i, line in enumerate(lines):
        stripped = line.rstrip()
        if stripped == begin_marker:
            begin_idx = i
        elif stripped == end_marker and begin_idx is not None:
            end_idx = i
            break

    if begin_idx is not None and end_idx is not None:
        return begin_idx, end_idx
    return None


# ---------------------------------------------------------------------------
# 合併路徑
# ---------------------------------------------------------------------------


def _build_managed_block(
    template_content: str, section_id: str, file_type: str
) -> list[str]:
    """建構管理區段（含標記）。"""
    lines = [_managed_begin(section_id, file_type)]
    for tl in template_content.splitlines():
        lines.append(tl)
    lines.append(_managed_end(section_id, file_type))
    return lines


def _build_user_block(user_lines: list[str], file_type: str) -> list[str]:
    """建構使用者區段（含標記）。"""
    block = [_user_begin(file_type)]
    block.extend(user_lines)
    block.append(_user_end(file_type))
    return block


def path_fresh_install(
    template_content: str, section_id: str, file_type: str
) -> tuple[str, MergeResult]:
    """路徑 1：全新安裝。"""
    managed = _build_managed_block(template_content, section_id, file_type)
    user = _build_user_block([], file_type)
    output = "\n".join(managed + [""] + user) + "\n"
    result = MergeResult(section_id=section_id, exit_code=EXIT_FRESH_INSTALL)
    return output, result


def path_update_managed(
    target_lines: list[str],
    template_content: str,
    section_id: str,
    file_type: str,
) -> tuple[str, MergeResult]:
    """路徑 2：目標已有標記，僅替換管理區段內容。"""
    span = _find_managed_section(target_lines, section_id, file_type)
    assert span is not None  # 呼叫端已檢查
    begin_idx, end_idx = span

    new_managed = _build_managed_block(template_content, section_id, file_type)
    new_lines = target_lines[:begin_idx] + new_managed + target_lines[end_idx + 1 :]
    output = "\n".join(new_lines)
    # 確保檔尾換行
    if not output.endswith("\n"):
        output += "\n"

    result = MergeResult(section_id=section_id, exit_code=EXIT_SUCCESS)
    return output, result


def path_first_upgrade(
    target_content: str,
    template_content: str,
    section_id: str,
    file_type: str,
    target_path: Path,
    dry_run: bool,
) -> tuple[str, MergeResult]:
    """路徑 3：首次升級（目標有內容但無任何 settingZsh 標記）。"""
    result = MergeResult(section_id=section_id, exit_code=EXIT_SUCCESS)

    # 備份
    if not dry_run:
        result.backup_path = _backup_file(target_path)
    else:
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        result.backup_path = str(target_path.with_name(f"{target_path.name}.bak.{ts}"))

    user_lines = target_content.splitlines()
    template_lines = template_content.splitlines()

    removed, kept, conflicts = _dedup_lines(user_lines, template_lines, file_type)

    result.removed_duplicates = removed
    result.value_conflicts = conflicts
    # kept_custom 僅計算非註解非空行
    result.kept_custom = [
        ln for ln in kept if not _is_comment_or_empty(ln, file_type)
    ]

    managed = _build_managed_block(template_content, section_id, file_type)
    user_block = _build_user_block(kept, file_type)
    output = "\n".join(managed + [""] + user_block) + "\n"

    return output, result


def _find_user_section(
    lines: list[str], file_type: str
) -> tuple[int, int] | None:
    """尋找使用者區段的 begin/end 行號。

    回傳 (begin_idx, end_idx) 或 None。
    """
    ub = _user_begin(file_type)
    ue = _user_end(file_type)

    begin_idx: int | None = None
    end_idx: int | None = None

    for i, line in enumerate(lines):
        stripped = line.rstrip()
        if stripped == ub and begin_idx is None:
            begin_idx = i
        elif stripped == ue:
            end_idx = i

    if begin_idx is not None and end_idx is not None:
        return begin_idx, end_idx
    return None


def _has_any_markers(lines: list[str]) -> bool:
    """判斷檔案是否包含任何 settingZsh 標記。"""
    return any(_is_marker_line(line) for line in lines)


def path_add_section(
    target_lines: list[str],
    template_content: str,
    section_id: str,
    file_type: str,
) -> tuple[str, MergeResult]:
    """路徑 4：檔案已有其他 settingZsh 標記，但缺少此 section → 插入新管理區段。

    新區段插入於 user:begin 標記之前。
    """
    result = MergeResult(section_id=section_id, exit_code=EXIT_SUCCESS)
    new_managed = _build_managed_block(template_content, section_id, file_type)

    user_span = _find_user_section(target_lines, file_type)
    if user_span is not None:
        insert_idx = user_span[0]
        new_lines = (
            target_lines[:insert_idx]
            + new_managed
            + [""]
            + target_lines[insert_idx:]
        )
    else:
        # 沒有 user 區段：附加在檔案末尾，並建立 user 區段
        new_lines = target_lines + [""] + new_managed + [""] + _build_user_block([], file_type)

    output = "\n".join(new_lines)
    if not output.endswith("\n"):
        output += "\n"

    return output, result


# ---------------------------------------------------------------------------
# 摘要輸出
# ---------------------------------------------------------------------------


def _c(text: str, code: str, *, use_color: bool) -> str:
    """條件式 ANSI 包裝。"""
    if not use_color:
        return text
    return f"{code}{text}{_RESET}"


def print_summary(result: MergeResult, *, use_color: bool) -> None:
    """輸出合併摘要。"""
    filename = result.filename or "(unknown)"
    header = f"=== 配置檔合併摘要：{filename} ==="
    footer = "=" * _visible_len(header)

    print(_c(header, _BOLD, use_color=use_color))
    print(f"  管理區段：已寫入 ({result.section_id})")

    # 移除重複
    n_dup = len(result.removed_duplicates)
    print(_c(f"  移除重複：{n_dup} 行", _YELLOW, use_color=use_color))
    for ln in result.removed_duplicates:
        print(_c(f"    - {ln}", _YELLOW, use_color=use_color))

    # 值衝突
    n_conf = len(result.value_conflicts)
    print(_c(f"  值衝突：{n_conf} 行", _RED, use_color=use_color))
    for user_ln, tpl_ln in result.value_conflicts:
        print(
            _c(
                f"    - 使用者: {user_ln} / 模板: {tpl_ln}",
                _RED,
                use_color=use_color,
            )
        )

    # 保留自訂
    n_kept = len(result.kept_custom)
    print(_c(f"  保留自訂：{n_kept} 行", _GREEN, use_color=use_color))

    # 備份
    if result.backup_path:
        print(_c(f"  備份檔案：{result.backup_path}", _CYAN, use_color=use_color))

    print(_c(footer, _BOLD, use_color=use_color))


def _visible_len(s: str) -> int:
    """計算去除 ANSI 跳脫碼後的可見長度。"""
    return len(re.sub(r"\033\[[0-9;]*m", "", s))


# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------


def merge(
    target_path: Path,
    template_path: Path,
    section_id: str,
    file_type: str,
    *,
    dry_run: bool = False,
) -> MergeResult:
    """執行合併並回傳結果。"""
    # 讀取模板
    template_content = _read_file(template_path)
    if template_content is None:
        print(f"錯誤：模板檔案不存在：{template_path}", file=sys.stderr)
        return MergeResult(exit_code=EXIT_ERROR)

    # 讀取目標
    target_content = _read_file(target_path)
    target_empty = target_content is None or target_content.strip() == ""

    # --- 路徑 1：全新安裝 ---
    if target_empty:
        output, result = path_fresh_install(template_content, section_id, file_type)
        result.filename = target_path.name
        if not dry_run:
            _write_file(target_path, output)
        print_summary(result, use_color=not dry_run and sys.stdout.isatty())
        return result

    # 目標存在且有內容
    assert target_content is not None
    target_lines = target_content.splitlines()

    # 檢查是否有完整的管理標記
    has_markers = _find_managed_section(target_lines, section_id, file_type) is not None

    # --- 路徑 2：已有標記 ---
    if has_markers:
        output, result = path_update_managed(
            target_lines, template_content, section_id, file_type
        )
        result.filename = target_path.name
        if not dry_run:
            _write_file(target_path, output)
        print_summary(result, use_color=not dry_run and sys.stdout.isatty())
        return result

    # --- 路徑 4：檔案有其他 settingZsh 標記，但缺少此 section ---
    if _has_any_markers(target_lines):
        output, result = path_add_section(
            target_lines, template_content, section_id, file_type
        )
        result.filename = target_path.name
        if not dry_run:
            _write_file(target_path, output)
        print_summary(result, use_color=not dry_run and sys.stdout.isatty())
        return result

    # --- 路徑 3：首次升級 ---
    output, result = path_first_upgrade(
        target_content, template_content, section_id, file_type, target_path, dry_run
    )
    result.filename = target_path.name
    if not dry_run:
        _write_file(target_path, output)
    print_summary(result, use_color=not dry_run and sys.stdout.isatty())
    return result


def build_parser() -> argparse.ArgumentParser:
    """建構 CLI 參數解析器。"""
    parser = argparse.ArgumentParser(
        description="配置檔合併引擎 — 將模板區段合併至目標配置檔，保留使用者自訂內容。",
    )
    parser.add_argument(
        "--target",
        required=True,
        help="目標檔案路徑",
    )
    parser.add_argument(
        "--template",
        required=True,
        help="模板檔案路徑",
    )
    parser.add_argument(
        "--section",
        required=True,
        help="區段 ID（如 zsh-base、editor、vimrc）",
    )
    parser.add_argument(
        "--type",
        required=True,
        choices=("zsh", "vim"),
        dest="file_type",
        help="檔案類型：zsh 或 vim",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="僅輸出摘要，不寫入檔案",
    )
    parser.add_argument(
        "--no-color",
        action="store_true",
        default=False,
        help="停用彩色輸出",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    """CLI 進入點。"""
    parser = build_parser()
    args = parser.parse_args(argv)

    # 決定是否使用色彩
    use_color = not args.no_color and sys.stdout.isatty()

    # 覆寫 print_summary 的色彩設定
    target_path = Path(args.target).expanduser().resolve()
    template_path = Path(args.template).expanduser().resolve()

    # 讀取模板（提前檢查）
    template_content = _read_file(template_path)
    if template_content is None:
        print(f"錯誤：模板檔案不存在：{template_path}", file=sys.stderr)
        return EXIT_ERROR

    # 讀取目標
    target_content = _read_file(target_path)
    target_empty = target_content is None or target_content.strip() == ""

    section_id = args.section
    file_type = args.file_type
    dry_run = args.dry_run

    # --- 路徑 1：全新安裝 ---
    if target_empty:
        output, result = path_fresh_install(template_content, section_id, file_type)
        result.filename = target_path.name
        if not dry_run:
            _write_file(target_path, output)
        print_summary(result, use_color=use_color)
        return result.exit_code

    # 目標存在且有內容
    assert target_content is not None
    target_lines = target_content.splitlines()
    has_markers = _find_managed_section(target_lines, section_id, file_type) is not None

    # --- 路徑 2：已有標記 ---
    if has_markers:
        output, result = path_update_managed(
            target_lines, template_content, section_id, file_type
        )
        result.filename = target_path.name
        if not dry_run:
            _write_file(target_path, output)
        print_summary(result, use_color=use_color)
        return result.exit_code

    # --- 路徑 4：檔案有其他 settingZsh 標記，但缺少此 section ---
    if _has_any_markers(target_lines):
        output, result = path_add_section(
            target_lines, template_content, section_id, file_type
        )
        result.filename = target_path.name
        if not dry_run:
            _write_file(target_path, output)
        print_summary(result, use_color=use_color)
        return result.exit_code

    # --- 路徑 3：首次升級 ---
    output, result = path_first_upgrade(
        target_content, template_content, section_id, file_type, target_path, dry_run
    )
    result.filename = target_path.name
    if not dry_run:
        _write_file(target_path, output)
    print_summary(result, use_color=use_color)
    return result.exit_code


if __name__ == "__main__":
    sys.exit(main())
