"""Neovim 預設選項的執行時整合測試。"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OPTIONS_FILE = PROJECT_ROOT / "nvim" / "lua" / "config" / "options.lua"
NVIM = shutil.which("nvim")


def _load_options(*, ssh: bool) -> dict[str, object]:
    """在隔離的 Neovim process 執行 options.lua 並回傳可觀察狀態。"""
    assert NVIM is not None
    env = os.environ.copy()
    for name in ("SSH_CLIENT", "SSH_CONNECTION", "SSH_TTY"):
        env.pop(name, None)
    if ssh:
        env["SSH_CONNECTION"] = "test-client test-server"

    lua_probe = (
        "io.stdout:write(vim.json.encode({"
        "number=vim.opt.number:get(),"
        "relativenumber=vim.opt.relativenumber:get(),"
        "clipboard=vim.g.clipboard or vim.NIL"
        "}) .. '\\n')"
    )
    result = subprocess.run(
        [
            NVIM,
            "--headless",
            "-u",
            "NONE",
            "-i",
            "NONE",
            f"+luafile {OPTIONS_FILE}",
            f"+lua {lua_probe}",
            "+qa",
        ],
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


@pytest.mark.skipif(NVIM is None, reason="Neovim 未安裝")
def test_defaults_to_absolute_line_numbers() -> None:
    """啟動後應顯示絕對行號，並關閉相對行號。"""
    options = _load_options(ssh=False)

    assert options["number"] is True
    assert options["relativenumber"] is False


@pytest.mark.skipif(NVIM is None, reason="Neovim 未安裝")
def test_uses_osc52_only_over_ssh() -> None:
    """SSH 強制使用 OSC 52，本機保留原生 clipboard provider。"""
    local_options = _load_options(ssh=False)
    ssh_options = _load_options(ssh=True)

    assert local_options["clipboard"] is None
    assert ssh_options["clipboard"] == "osc52"
