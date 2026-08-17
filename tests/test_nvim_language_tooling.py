"""Neovim P0 語言工具 manifest 測試。"""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
NVIM = shutil.which("nvim")


def _runtime_manifest() -> dict[str, object]:
    """以隔離 process 讀取 LSP 選擇與自訂 server manifest。"""
    assert NVIM is not None
    options = PROJECT_ROOT / "nvim" / "lua" / "config" / "options.lua"
    languages = PROJECT_ROOT / "nvim" / "lua" / "plugins" / "languages.lua"
    tooling = PROJECT_ROOT / "nvim" / "lua" / "config" / "tooling.lua"
    lua_probe = (
        f"dofile({json.dumps(str(options))});"
        f"local ok,specs=pcall(dofile,{json.dumps(str(languages))});"
        "if not ok then io.stderr:write(tostring(specs)); os.exit(1) end;"
        f"local tools_ok,tooling=pcall(dofile,{json.dumps(str(tooling))});"
        "if not tools_ok then io.stderr:write(tostring(tooling)); os.exit(1) end;"
        "local servers={}; local intelephense_mason=nil;"
        "for _,spec in ipairs(specs) do "
        "if spec[1]=='neovim/nvim-lspconfig' and type(spec.opts)=='table' then "
        "if type(spec.init)=='function' then spec.init() end;"
        "for name,server in pairs(spec.opts.servers or {}) do table.insert(servers,name);"
        "if name=='intelephense' then intelephense_mason=server.mason end end "
        "end end;"
        "table.sort(servers);"
        "local result={php=vim.g.lazyvim_php_lsp,python=vim.g.lazyvim_python_lsp,"
        "ruff=vim.g.lazyvim_python_ruff,servers=servers,"
        "intelephense_mason=intelephense_mason,"
        "compose_ft=vim.filetype.match({filename='/tmp/compose.yaml'}),tooling=tooling};"
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
def test_declares_p0_language_extras_and_single_tool_roles() -> None:
    """P0 Extra、LSP 選擇與 Python formatter 應固定且不重複。"""
    lazyvim = json.loads((PROJECT_ROOT / "nvim" / "lazyvim.json").read_text())
    extras = set(lazyvim["extras"])
    manifest = _runtime_manifest()

    assert {
        "lazyvim.plugins.extras.lang.yaml",
        "lazyvim.plugins.extras.lang.docker",
        "lazyvim.plugins.extras.formatting.black",
    } <= extras
    assert not any("ruff" in extra and "format" in extra for extra in extras)
    assert not any(".extras.dap." in extra or ".extras.test." in extra or ".extras.ai." in extra for extra in extras)
    assert manifest["php"] == "intelephense"
    assert manifest["python"] == "pyright"
    assert manifest["ruff"] == "ruff"
    assert manifest["servers"] == ["cssls", "html", "intelephense"]
    assert manifest["intelephense_mason"] is False
    assert manifest["compose_ft"] == "yaml.docker-compose"

    lsp_packages = {item["mason"] for item in manifest["tooling"]["lsp"]}
    tool_packages = {item["mason"] for item in manifest["tooling"]["tools"]}
    assert {"intelephense", "pyright", "ruff", "vtsls", "json-lsp", "marksman"} <= lsp_packages
    assert {"black", "prettier", "phpcs", "php-cs-fixer", "hadolint"} <= tool_packages
    assert lsp_packages.isdisjoint(tool_packages)


def test_runtime_acceptance_uses_disposable_fixture_copy() -> None:
    """LSP 驗收不得讓 server 在 repo fixture 留下 build artifacts。"""
    script = (PROJECT_ROOT / "tests" / "accept_nvim_runtime.sh").read_text()

    assert 'RUNTIME_FIXTURE_DIR="$(mktemp -d /tmp/settingzsh-nvim-accept.XXXXXXXX)"' in script
    assert 'cp -R "$SOURCE_FIXTURE_DIR/." "$RUNTIME_FIXTURE_DIR/"' in script
    assert 'mkdir -p "$RUNTIME_FIXTURE_DIR/.git"' in script
    assert 'file="$RUNTIME_FIXTURE_DIR/$relative_file"' in script
    assert 'file="$PROJECT_DIR/tests/fixtures/nvim-runtime/$relative_file"' not in script


@pytest.mark.skipif(NVIM is None, reason="Neovim 未安裝")
def test_markdownlint_diagnostics_are_disabled_without_removing_markdown_tools() -> None:
    """預設不發布 Markdown 格式診斷，但保留語言、格式與 preview Extra。"""
    plugin = PROJECT_ROOT / "nvim" / "lua" / "plugins" / "markdown.lua"
    lua_probe = (
        f"local ok,specs=pcall(dofile,{json.dumps(str(plugin))});"
        "if not ok then io.stderr:write(tostring(specs)); os.exit(1) end;"
        "local opts={linters_by_ft={markdown={'markdownlint-cli2'},"
        "['markdown.mdx']={'markdownlint-cli2'},python={'ruff'}}};"
        "local found=false;"
        "for _,spec in ipairs(specs) do "
        "if spec[1]=='mfussenegger/nvim-lint' then spec.opts(nil,opts); found=true end "
        "end;"
        "local result={found=found,markdown=opts.linters_by_ft.markdown==nil,"
        "markdown_mdx=opts.linters_by_ft['markdown.mdx']==nil,"
        "python=opts.linters_by_ft.python};"
        "io.stdout:write(vim.json.encode(result)..'\\n')"
    )
    result = subprocess.run(
        [NVIM, "--headless", "-u", "NONE", "-i", "NONE", f"+lua {lua_probe}", "+qa"],
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, result.stderr
    state = json.loads(result.stdout)
    lazyvim = json.loads((PROJECT_ROOT / "nvim" / "lazyvim.json").read_text())
    tooling = _runtime_manifest()["tooling"]

    assert state == {
        "found": True,
        "markdown": True,
        "markdown_mdx": True,
        "python": ["ruff"],
    }
    assert "lazyvim.plugins.extras.lang.markdown" in lazyvim["extras"]
    assert "lazyvim.plugins.extras.formatting.prettier" in lazyvim["extras"]
    assert {item["mason"] for item in tooling["lsp"]} >= {"marksman"}
    assert {item["mason"] for item in tooling["tools"]} >= {"markdownlint-cli2"}
