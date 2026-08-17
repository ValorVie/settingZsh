"""Neovim trailing-whitespace fallback 測試。"""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
NVIM = shutil.which("nvim")


def _run_probe(path: Path, *, filetype: str, editorconfig: str | None = None) -> dict[str, object]:
    assert NVIM is not None
    helper = PROJECT_ROOT / "nvim" / "lua" / "config" / "whitespace.lua"
    editorconfig_lua = (
        f"vim.b.editorconfig={{trim_trailing_whitespace={json.dumps(editorconfig)}}};"
        if editorconfig is not None
        else "vim.b.editorconfig={};"
    )
    lua_probe = (
        f"local ok,ws=pcall(dofile,{json.dumps(str(helper))});"
        "if not ok then io.stderr:write(tostring(ws)); os.exit(1) end;"
        f"vim.bo.filetype={json.dumps(filetype)};"
        f"{editorconfig_lua}"
        "vim.fn.setreg('/', 'needle'); vim.api.nvim_win_set_cursor(0,{2,0});"
        "local changed=ws.trim(0);"
        "local result={changed=changed,lines=vim.api.nvim_buf_get_lines(0,0,-1,false),"
        "cursor=vim.api.nvim_win_get_cursor(0),search=vim.fn.getreg('/')};"
        "io.stdout:write(vim.json.encode(result)..'\\n')"
    )
    result = subprocess.run(
        [NVIM, "--headless", "-u", "NONE", "-i", "NONE", str(path), f"+lua {lua_probe}", "+qa!"],
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


@pytest.mark.skipif(NVIM is None, reason="Neovim 未安裝")
def test_trims_plain_text_and_preserves_view_and_search(tmp_path: Path) -> None:
    fixture = tmp_path / "example.lua"
    fixture.write_text("needle  \nsecond \t\n")

    result = _run_probe(fixture, filetype="lua")

    assert result == {
        "changed": True,
        "lines": ["needle", "second"],
        "cursor": [2, 0],
        "search": "needle",
    }


@pytest.mark.skipif(NVIM is None, reason="Neovim 未安裝")
@pytest.mark.parametrize(
    ("filetype", "editorconfig"),
    (("markdown", None), ("lua", "false")),
)
def test_preserves_trailing_whitespace_for_markdown_or_editorconfig(
    tmp_path: Path,
    filetype: str,
    editorconfig: str | None,
) -> None:
    fixture = tmp_path / "example.txt"
    fixture.write_text("hard break  \nsecond\n")

    result = _run_probe(fixture, filetype=filetype, editorconfig=editorconfig)

    assert result["changed"] is False
    assert result["lines"] == ["hard break  ", "second"]


@pytest.mark.skipif(NVIM is None, reason="Neovim 未安裝")
def test_editorconfig_controls_indent_eol_final_newline_and_trim(tmp_path: Path) -> None:
    """內建 EditorConfig 應優先於個人 fallback。"""
    (tmp_path / ".editorconfig").write_text(
        "root = true\n\n[*]\nindent_style = space\nindent_size = 2\n"
        "end_of_line = crlf\ninsert_final_newline = true\ntrim_trailing_whitespace = false\n"
    )
    fixture = tmp_path / "example.lua"
    fixture.write_text("first  \nsecond\n")
    helper = PROJECT_ROOT / "nvim" / "lua" / "config" / "whitespace.lua"
    lua_probe = (
        "vim.api.nvim_create_augroup('nvim.editorconfig',{clear=true});"
        "require('editorconfig').config(0);"
        f"local ws=dofile({json.dumps(str(helper))});"
        "local changed=ws.trim(0);"
        "local result={changed=changed,shiftwidth=vim.bo.shiftwidth,fileformat=vim.bo.fileformat,"
        "fixendofline=vim.bo.fixendofline,editorconfig=vim.b.editorconfig};"
        "io.stdout:write(vim.json.encode(result)..'\\n')"
    )
    result = subprocess.run(
        [NVIM, "--headless", "-u", "NONE", "-i", "NONE", str(fixture), f"+lua {lua_probe}", "+qa!"],
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    data = json.loads(result.stdout)
    assert data == {
        "changed": False,
        "shiftwidth": 2,
        "fileformat": "dos",
        "fixendofline": True,
        "editorconfig": {
            "end_of_line": "crlf",
            "indent_size": "2",
            "indent_style": "space",
            "insert_final_newline": "true",
            "root": True,
            "trim_trailing_whitespace": "false",
        },
    }, data


@pytest.mark.skipif(NVIM is None, reason="Neovim 未安裝")
def test_skips_nofile_buffers() -> None:
    """非一般 buffer 不應套用 trimming fallback。"""
    helper = PROJECT_ROOT / "nvim" / "lua" / "config" / "whitespace.lua"
    lua_probe = (
        f"local ws=dofile({json.dumps(str(helper))});"
        "vim.bo.buftype='nofile'; vim.api.nvim_buf_set_lines(0,0,-1,false,{'keep  '});"
        "local result={changed=ws.trim(0),line=vim.api.nvim_get_current_line()};"
        "io.stdout:write(vim.json.encode(result)..'\\n')"
    )
    result = subprocess.run(
        [NVIM, "--headless", "-u", "NONE", "-i", "NONE", f"+lua {lua_probe}", "+qa!"],
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout) == {"changed": False, "line": "keep  "}
