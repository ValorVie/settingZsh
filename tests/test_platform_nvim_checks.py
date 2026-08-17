"""平台測試必須把 Neovim 配置缺失視為失敗。"""

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_platform_tests_fail_when_nvim_config_is_missing() -> None:
    """Linux、macOS、Windows 都應檢查 init.lua 並走 failure path。"""
    linux = (PROJECT_ROOT / "tests" / "test_linux.sh").read_text()
    mac = (PROJECT_ROOT / "tests" / "test_mac.sh").read_text()
    windows = (PROJECT_ROOT / "tests" / "test_win.ps1").read_text()

    assert 'fail "nvim config 不存在' in linux
    assert 'fail "nvim config 不存在' in mac
    assert 'Test-Fail "nvim config not deployed' in windows
