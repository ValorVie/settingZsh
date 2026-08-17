## Purpose

建立與既有 VS Code 使用習慣相符的 P0 語言工具鏈，並以實際 executable、LSP attach 與專案設定作為可用性判準。

## ADDED Requirements

### Requirement: P0 語言能力清單

Neovim 配置 SHALL 為 PHP、Python、Rust、TypeScript／JavaScript、HTML／CSS、JSON、YAML、Docker／Compose 與 Markdown 宣告單一主要語言伺服器與格式化路徑。

| 語言 | 主要能力 |
|------|----------|
| PHP | Intelephense、PHPCS／php-cs-fixer、專案型 PHPStan |
| Python | Pyright、Ruff analysis、Black formatting、虛擬環境切換 |
| Rust | rust-analyzer 與既有 Cargo 整合 |
| TypeScript／JavaScript | vtsls、ESLint、Prettier |
| HTML／CSS | html、cssls、Prettier |
| JSON | jsonls 與 SchemaStore |
| YAML | yamlls 與 SchemaStore |
| Docker／Compose | Docker 與 Compose language server、Hadolint |
| Markdown | Marksman、markdownlint、TOC 與 preview |

#### Scenario: PHP 智慧提示

- **WHEN** 使用者開啟有效 PHP workspace
- **THEN** Intelephense SHALL attach，definition、references、rename 與 diagnostics SHALL 可用

#### Scenario: Python 分析與格式化分工

- **WHEN** 使用者開啟有效 Python workspace
- **THEN** Pyright 與 Ruff SHALL 負責型別／靜態分析，Black SHALL 負責預設格式化

#### Scenario: Web 與設定檔語言

- **WHEN** 使用者開啟 TypeScript、HTML、CSS、JSON、YAML、Dockerfile、Compose 或 Markdown fixture
- **THEN** 對應的主要語言伺服器 SHALL attach，且 formatter／linter SHALL 不重複執行同一責任

### Requirement: 編輯器工具與專案依賴分界

由編輯器管理的 LSP、formatter 與通用 linter SHALL 可透過 Mason 安裝；專案鎖定的 runtime、library 與分析依賴 SHALL 由專案 package manager 管理。

#### Scenario: Mason 管理編輯器工具

- **WHEN** 使用者完成 Neovim editor tool 安裝
- **THEN** 所有已選 P0 LSP 與通用 formatter SHALL 可在 Mason 或系統 PATH 找到 executable

#### Scenario: 不改寫專案依賴

- **WHEN** workspace 缺少 Composer、npm、Cargo 或 Python 專案依賴
- **THEN** Neovim 安裝流程 SHALL 回報缺少項目，不得自動修改專案 manifest 或 lockfile

### Requirement: PHPStan 使用專案版本

PHPStan lint SHALL 只在目前 PHP workspace 可找到專案版本與設定時啟用，不得以全域 PHPStan 取代專案版本。

#### Scenario: 專案有 PHPStan

- **WHEN** workspace 含可執行的 `vendor/bin/phpstan` 與有效設定
- **THEN** PHPStan diagnostics SHALL 可在該 workspace 執行

#### Scenario: 專案沒有 PHPStan

- **WHEN** workspace 沒有專案 PHPStan
- **THEN** Neovim SHALL 略過 PHPStan 並保留其他 PHP LSP／lint 功能，不得顯示持續性 command-not-found 錯誤

### Requirement: 缺少工具時提供可行診斷

配置 SHALL 區分已宣告 Extra、已安裝 executable 與已 attach client，並在缺少工具時提供工具名稱與修復入口。

#### Scenario: LSP 未安裝

- **WHEN** 語言 Extra 已啟用但對應 executable 不存在
- **THEN** 健康檢查 SHALL 失敗並列出缺少的 server，不得把 Extra 已啟用報告為語言支援完成

#### Scenario: LSP 已安裝但未 attach

- **WHEN** executable 存在但代表性 fixture 沒有 active client
- **THEN** runtime 驗收 SHALL 失敗並保留 LSP log 路徑
