"""Unix setup 的配置合併狀態碼整合測試。"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SETUP_SCRIPTS = ("setup_linux.sh", "setup_mac.sh")


def _extract_merge_config(script_path: Path) -> str:
    """從 setup 腳本擷取實際的 merge_config 函式。"""
    lines = script_path.read_text(encoding="utf-8").splitlines()
    start = lines.index("merge_config() {")
    end = lines.index("}", start)
    return "\n".join(lines[start : end + 1])


@pytest.mark.parametrize("script_name", SETUP_SCRIPTS)
@pytest.mark.parametrize(
    ("merge_status", "expected_status"),
    ((0, 0), (1, 1), (2, 0)),
)
def test_merge_config_normalizes_success_statuses(
    script_name: str,
    merge_status: int,
    expected_status: int,
) -> None:
    """一般成功與全新安裝應繼續，真正錯誤應往上傳遞。"""
    merge_function = _extract_merge_config(PROJECT_ROOT / script_name)
    shell_program = f"""
set -e
uv() {{ return "$MOCK_MERGE_STATUS"; }}
SCRIPT_DIR=/unused
{merge_function}
merge_config /unused/target /unused/template test-section zsh
"""
    env = os.environ.copy()
    env["MOCK_MERGE_STATUS"] = str(merge_status)

    result = subprocess.run(
        ["bash", "-c", shell_program],
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )

    assert result.returncode == expected_status, result.stderr
