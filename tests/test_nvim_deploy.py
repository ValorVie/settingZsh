"""Neovim 配置部署的等冪行為測試。"""

from __future__ import annotations

import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEPLOY_HELPER = PROJECT_ROOT / "lib" / "deploy_nvim_config.sh"


def _run_deploy(source: Path, target: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            "bash",
            "-c",
            'source "$1"; deploy_nvim_config "$2" "$3"',
            "deploy-nvim-test",
            str(DEPLOY_HELPER),
            str(source),
            str(target),
        ],
        check=False,
        capture_output=True,
        text=True,
    )


def _write_source(source: Path, marker: str) -> None:
    (source / "lua" / "config").mkdir(parents=True, exist_ok=True)
    (source / "init.lua").write_text(f'vim.g.deploy_marker = "{marker}"\n')
    (source / "lua" / "config" / "options.lua").write_text("vim.opt.number = true\n")


def _snapshot(root: Path) -> dict[str, bytes]:
    return {
        str(path.relative_to(root)): path.read_bytes()
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


def test_first_deploy_and_identical_rerun_are_idempotent(tmp_path: Path) -> None:
    """首次建立配置；相同來源重跑應 no-op 且不建立 backup。"""
    source = tmp_path / "source"
    target = tmp_path / "config" / "nvim"
    _write_source(source, "v1")

    first = _run_deploy(source, target)
    assert first.returncode == 0, first.stderr
    first_snapshot = _snapshot(target)
    first_mtime = target.stat().st_mtime_ns

    second = _run_deploy(source, target)
    assert second.returncode == 0, second.stderr
    assert _snapshot(target) == first_snapshot
    assert target.stat().st_mtime_ns == first_mtime
    assert not Path(f"{target}.bak").exists()
    assert "已是最新版本，略過" in second.stdout


def test_existing_config_replaces_fixed_backup_without_nesting(tmp_path: Path) -> None:
    """既有 backup 應被目前配置取代，不得產生 .bak/nvim。"""
    source = tmp_path / "source"
    target = tmp_path / "config" / "nvim"
    backup = Path(f"{target}.bak")
    _write_source(source, "v1")
    target.mkdir(parents=True)
    (target / "init.lua").write_text('vim.g.deploy_marker = "custom"\n')
    backup.mkdir()
    (backup / "init.lua").write_text('vim.g.deploy_marker = "older"\n')

    result = _run_deploy(source, target)

    assert result.returncode == 0, result.stderr
    assert _snapshot(target) == _snapshot(source)
    assert (backup / "init.lua").read_text() == 'vim.g.deploy_marker = "custom"\n'
    assert not (backup / "nvim").exists()


def test_source_update_backs_up_previous_deployment(tmp_path: Path) -> None:
    """來源更新後應部署新版，並以固定 backup 保存前一版。"""
    source = tmp_path / "source"
    target = tmp_path / "config" / "nvim"
    backup = Path(f"{target}.bak")
    _write_source(source, "v1")
    assert _run_deploy(source, target).returncode == 0

    _write_source(source, "v2")
    update = _run_deploy(source, target)

    assert update.returncode == 0, update.stderr
    assert (target / "init.lua").read_text() == 'vim.g.deploy_marker = "v2"\n'
    assert (backup / "init.lua").read_text() == 'vim.g.deploy_marker = "v1"\n'
    backup_snapshot = _snapshot(backup)

    repeat = _run_deploy(source, target)
    assert repeat.returncode == 0, repeat.stderr
    assert _snapshot(backup) == backup_snapshot
    assert not (backup / "nvim").exists()


def test_invalid_source_stops_without_changing_target(tmp_path: Path) -> None:
    """來源缺少 init.lua 時必須非零停止並保留目前配置。"""
    source = tmp_path / "source"
    target = tmp_path / "config" / "nvim"
    source.mkdir()
    target.mkdir(parents=True)
    (target / "init.lua").write_text('vim.g.deploy_marker = "keep"\n')
    before = _snapshot(target)

    result = _run_deploy(source, target)

    assert result.returncode != 0
    assert _snapshot(target) == before
    assert not Path(f"{target}.bak").exists()
