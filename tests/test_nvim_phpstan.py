"""PHPStan 專案版本偵測測試。"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
NVIM = shutil.which("nvim")


def _available(root: Path) -> bool:
    assert NVIM is not None
    helper = PROJECT_ROOT / "nvim" / "lua" / "config" / "phpstan.lua"
    lua_probe = (
        f"local ok,phpstan=pcall(dofile,{json.dumps(str(helper))});"
        "if not ok then io.stderr:write(tostring(phpstan)); os.exit(1) end;"
        f"io.stdout:write(vim.json.encode(phpstan.available({json.dumps(str(root))}))..'\\n')"
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
def test_phpstan_requires_project_binary_and_config(tmp_path: Path) -> None:
    """只有專案 binary 與設定同時存在時才啟用 PHPStan。"""
    binary = tmp_path / "vendor" / "bin" / "phpstan"
    binary.parent.mkdir(parents=True)
    binary.write_text("#!/bin/sh\n")
    os.chmod(binary, 0o755)

    assert _available(tmp_path) is False

    (tmp_path / "phpstan.neon").write_text("parameters:\n")
    assert _available(tmp_path) is True

    binary.unlink()
    assert _available(tmp_path) is False
