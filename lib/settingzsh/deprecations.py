from __future__ import annotations

DEPRECATED_GUIDANCE: dict[str, str] = {
    "setup": (
        "setup 已停用。請改用 `chezmoi init --apply`，"
        "並在需要檢查既有 shell 時先跑 `preflight`，再視情況用 `adopt` 或 `legacy-import`。"
    ),
    "update": (
        "update 已停用。請改用 `chezmoi update`，"
        "並在既有 shell 上先用 `preflight`、`adopt` 或 `legacy-import` 收斂。"
    ),
    "reconcile": (
        "reconcile 已停用。請改用 `chezmoi apply`，"
        "並搭配 `preflight`、`adopt`、`legacy-import` 做 read-only 檢查與舊設定收斂。"
    ),
    "migrate": (
        "migrate 已停用。請改用 `legacy-import`，"
        "並先跑 `preflight` / `adopt` 檢查既有 shell 狀態。"
    ),
}

