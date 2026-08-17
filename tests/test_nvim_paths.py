"""Neovim 路徑複製 helper 的執行時測試。"""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
NVIM = shutil.which("nvim")


def _probe() -> dict[str, object]:
    """在隔離 process 執行 path helper。"""
    assert NVIM is not None
    helper = PROJECT_ROOT / "nvim" / "lua" / "config" / "path.lua"
    lua_probe = (
        f"local ok,paths=pcall(dofile,{json.dumps(str(helper))});"
        "if not ok then io.stderr:write(tostring(paths)); os.exit(1) end;"
        "local root='/workspace/project';"
        "local inside='/workspace/project/src/main.lua';"
        "local outside='/tmp/example.lua';"
        "vim.fn.setreg('a','sentinel');"
        "local unnamed_ok=paths.copy('',{root=root,register='a'});"
        "local result={"
        "relative=paths.relative(inside,root),"
        "outside=paths.relative(outside,root),"
        "with_line=paths.format(inside,{root=root,line=42}),"
        "unnamed_ok=unnamed_ok,"
        "register=vim.fn.getreg('a')"
        "};"
        "io.stdout:write(vim.json.encode(result)..'\\n')"
    )
    result = subprocess.run(
        [NVIM, "--headless", "-u", "NONE", "-i", "NONE", f"+lua {lua_probe}", "+qa"],
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


@pytest.mark.skipif(NVIM is None, reason="Neovim 未安裝")
def test_formats_project_relative_and_absolute_fallback_paths() -> None:
    """專案內使用相對路徑，root 外回退絕對路徑，未命名不覆寫 register。"""
    result = _probe()

    assert result["relative"] == "src/main.lua"
    assert result["outside"] == "/tmp/example.lua"
    assert result["with_line"] == "src/main.lua:42"
    assert result["unnamed_ok"] is False
    assert result["register"] == "sentinel"


@pytest.mark.skipif(NVIM is None, reason="Neovim 未安裝")
def test_registers_buffer_path_keymaps() -> None:
    """一般 buffer 應提供相對路徑與 path:line 快捷鍵。"""
    keymaps = PROJECT_ROOT / "nvim" / "lua" / "config" / "keymaps.lua"
    lua_root = PROJECT_ROOT / "nvim" / "lua"
    lua_probe = (
        f"package.path={json.dumps(str(lua_root / '?.lua'))}..';'..package.path;"
        "LazyVim={root=function() return '/workspace/project' end};"
        f"dofile({json.dumps(str(keymaps))});"
        "local path_map=vim.fn.maparg('<leader>yp','n',false,true);"
        "local line_map=vim.fn.maparg('<leader>yL','n',false,true);"
        "io.stdout:write(vim.json.encode({path=path_map.desc,line=line_map.desc})..'\\n')"
    )
    result = subprocess.run(
        [NVIM, "--headless", "-u", "NONE", "-i", "NONE", f"+lua {lua_probe}", "+qa"],
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    mappings = json.loads(result.stdout)

    assert mappings == {
        "path": "Copy Project-Relative Path",
        "line": "Copy Project-Relative Path with Line",
    }
