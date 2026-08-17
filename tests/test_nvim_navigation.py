"""Neovim workspace navigation 配置測試。"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
NVIM = shutil.which("nvim")


def _editor_spec() -> dict[str, object]:
    """以隔離 Neovim process 載入 editor plugin spec。"""
    assert NVIM is not None
    editor_file = PROJECT_ROOT / "nvim" / "lua" / "plugins" / "editor.lua"
    lua_root = PROJECT_ROOT / "nvim" / "lua"
    lua_probe = (
        f"package.path={json.dumps(str(lua_root / '?.lua'))}..';'..package.path;"
        f"local specs=dofile({json.dumps(str(editor_file))});"
        "local result={plugins={}};"
        "for _,spec in ipairs(specs) do "
        "local name=spec[1];"
        "table.insert(result.plugins,name);"
        "if name=='folke/snacks.nvim' then "
        "local opts=type(spec.opts)=='table' and spec.opts or {};"
        "local picker=opts.picker or {};"
        "local sources=picker.sources or {};"
        "result.plugin=name; result.sources=sources;"
        "end end;"
        "io.stdout:write(vim.json.encode(result)..'\\n')"
    )
    result = subprocess.run(
        [NVIM, "--headless", "-u", "NONE", "-i", "NONE", f"+lua {lua_probe}", "+qa"],
        check=False,
        capture_output=True,
        text=True,
        env=os.environ.copy(),
    )
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


@pytest.mark.skipif(NVIM is None, reason="Neovim 未安裝")
def test_uses_single_snacks_navigation_backend() -> None:
    """Picker 與 explorer 應固定使用 Snacks 並共用排除意圖。"""
    lazyvim = json.loads((PROJECT_ROOT / "nvim" / "lazyvim.json").read_text())
    lockfile = json.loads((PROJECT_ROOT / "nvim" / "lazy-lock.json").read_text())
    extras = set(lazyvim["extras"])
    spec = _editor_spec()

    assert "lazyvim.plugins.extras.editor.snacks_picker" in extras
    assert "lazyvim.plugins.extras.editor.snacks_explorer" in extras
    assert "snacks.nvim" in lockfile
    assert {"fzf-lua", "telescope.nvim", "neo-tree.nvim"}.isdisjoint(lockfile)
    assert spec["plugin"] == "folke/snacks.nvim"
    assert set(spec["plugins"]) == {"folke/snacks.nvim"}

    sources = spec["sources"]
    expected = {"node_modules", "vendor", "target", "dist", "build", ".git"}
    for source in ("files", "grep", "explorer"):
        assert expected <= set(sources[source]["exclude"])
        assert sources[source]["follow"] is False

    explorer_keys = sources["explorer"]["win"]["list"]["keys"]
    assert explorer_keys["Y"] == "copy_absolute_path"
    assert explorer_keys["gY"] == "copy_relative_path"
