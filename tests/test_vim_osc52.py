"""原生 Vim 經 SSH 複製到 OSC 52 clipboard 的行為測試。"""

from __future__ import annotations

import base64
import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
VIMRC = PROJECT_ROOT / "vim" / ".vimrc"
VIM = shutil.which("vim")


def _run_yank(tmp_path: Path, keys: str) -> tuple[subprocess.CompletedProcess[str], bytes]:
    fixture = tmp_path / "fixture.txt"
    capture = tmp_path / "osc52.out"
    fixture.write_text("alpha beta\nsecond line\nthird line\n")
    environment = os.environ.copy()
    environment["SSH_CONNECTION"] = "test"

    result = subprocess.run(
        [
            VIM,
            "-Nu",
            "NONE",
            "-n",
            "-es",
            "--cmd",
            f"let g:settingzsh_osc52_tty = {json.dumps(str(capture))}",
            "--cmd",
            f"execute 'source ' . fnameescape({json.dumps(str(VIMRC))})",
            str(fixture),
            "-c",
            f"call feedkeys({json.dumps(keys)}, 'xt')",
            "-c",
            "if !empty(v:errmsg) | cquit 1 | endif",
            "-c",
            "qa!",
        ],
        check=False,
        capture_output=True,
        text=True,
        env=environment,
    )
    return result, capture.read_bytes() if capture.exists() else b""


def _decode_osc52(payload: bytes) -> bytes:
    prefix = b"\x1b]52;c;"
    assert payload.startswith(prefix)
    assert payload.endswith(b"\x07")
    return base64.b64decode(payload[len(prefix) : -1], validate=True)


@pytest.mark.skipif(VIM is None, reason="Vim 未安裝")
def test_visual_quoteplus_y_sends_selected_lines_over_osc52(tmp_path: Path) -> None:
    """Visual line selection 後的 `\"+y` 應輸出正確 OSC52 payload。"""
    result, payload = _run_yank(tmp_path, 'ggVj"+y')

    assert result.returncode == 0, result.stderr
    assert _decode_osc52(payload) == b"alpha beta\nsecond line\n"


@pytest.mark.skipif(VIM is None, reason="Vim 未安裝")
def test_normal_quoteplus_y_motion_sends_motion_text_over_osc52(tmp_path: Path) -> None:
    """Normal mode 的 `\"+y{motion}` 應維持 operator-pending 語意。"""
    result, payload = _run_yank(tmp_path, 'gg"+ye')

    assert result.returncode == 0, result.stderr
    assert _decode_osc52(payload) == b"alpha"


@pytest.mark.skipif(VIM is None, reason="Vim 未安裝")
def test_normal_quoteplus_yy_sends_current_line_over_osc52(tmp_path: Path) -> None:
    """常用的 `\"+yy` 應複製目前整行。"""
    result, payload = _run_yank(tmp_path, 'gg"+yy')

    assert result.returncode == 0, result.stderr
    assert _decode_osc52(payload) == b"alpha beta\n"
