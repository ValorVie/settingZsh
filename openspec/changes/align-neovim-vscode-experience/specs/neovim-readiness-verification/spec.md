## Purpose

建立不依賴印象的 Neovim 驗收方式，分別驗證配置、外掛、可執行工具與實際語言 client，並保留無網路測試與人工停止點。

## ADDED Requirements

### Requirement: 無網路配置測試

專案 SHALL 提供不下載外掛、不安裝工具、不修改真實 Neovim data directory 的自動化測試，以驗證配置檔可載入及核心行為。

#### Scenario: 隔離載入選項與快捷鍵 Helper

- **WHEN** 執行 Neovim 配置測試
- **THEN** 測試 SHALL 使用隔離 process／fixture 驗證選項、路徑運算與安全停止條件，不得讀寫真實使用者配置

#### Scenario: 驗證 Extra 與工具 manifest

- **WHEN** 執行無網路測試
- **THEN** SHALL 驗證必要 Extra、主要 LSP 選擇與 formatter／linter 宣告，且不得連線下載 package

### Requirement: 平台安裝測試確認配置已部署

當 editor feature 被標記為已安裝時，Linux、macOS 與 Windows 測試 SHALL 把缺少 Neovim `init.lua` 視為失敗，不得只確認 `nvim` binary 存在。

#### Scenario: Editor feature 已安裝且配置存在

- **WHEN** features 標記含 `editor` 且目標 `init.lua` 存在
- **THEN** 平台測試 SHALL 通過配置部署檢查

#### Scenario: Editor feature 已安裝但配置缺失

- **WHEN** features 標記含 `editor` 或偵測到 `nvim`，但目標 `init.lua` 不存在
- **THEN** 平台測試 SHALL 失敗並輸出預期配置路徑

### Requirement: 安裝後 Runtime 驗收

專案 SHALL 提供明確的安裝後驗收流程，分別檢查 LazyVim、主要 picker/explorer、必要 executable 與代表性 LSP attach。

#### Scenario: LazyVim 與主要後端

- **WHEN** 完成 editor 安裝並執行 runtime 驗收
- **THEN** LazyVim SHALL 可啟動，且只選定一組主要 picker/explorer

#### Scenario: 語言工具 executable

- **WHEN** 執行 P0 工具檢查
- **THEN** 每個必要 server／formatter SHALL 可在 Mason bin 或系統 PATH 執行

#### Scenario: 代表性 LSP attach

- **WHEN** 依序開啟 PHP、Python、TypeScript、JSON、YAML、Docker／Compose 與 Markdown fixture
- **THEN** 預期 client SHALL attach；缺少 client SHALL 使該語言驗收失敗

### Requirement: 健康檢查分類

驗收 SHALL 區分本次啟用功能的 blocking error、未使用 provider 的 optional warning 與尚未執行的人工驗收。

#### Scenario: Optional provider 缺失

- **WHEN** 健康檢查只回報未使用的 Ruby、Perl、Node provider 或 LuaRocks
- **THEN** 報告 SHALL 記為 optional warning，不得因此宣稱 P0 失敗

#### Scenario: 已啟用功能失敗

- **WHEN** 主要 picker、formatter、LSP 或 preview 回報缺少 executable／client
- **THEN** 報告 SHALL 記為 blocking error，並列出修復與重新驗收入口

#### Scenario: 未執行人工測試

- **WHEN** OSC 52 copy/paste、browser preview 或真實專案 LSP 尚未人工驗收
- **THEN** 狀態 SHALL 標記為未驗證，不得記為通過

### Requirement: Neovim 配置部署可安全重跑

Linux 與 macOS 的 editor 安裝流程 SHALL 允許使用者重複部署相同 Neovim 配置，不得產生巢狀 backup、累加檔案或因既有 `.bak` 中止。

#### Scenario: 首次部署與相同內容重跑

- **WHEN** 目標不存在時部署一次，隨後以相同來源再次部署
- **THEN** 第一次 SHALL 建立完整配置，第二次 SHALL 安全 no-op，目標內容與 backup 狀態 SHALL 不變

#### Scenario: 既有配置或來源更新

- **WHEN** 目標內容與來源不同，或固定 `.bak` 已存在
- **THEN** 部署 SHALL 以目前目標更新固定 backup、套用完整來源，且 SHALL NOT 建立 `.bak/nvim` 或其他巢狀 backup

#### Scenario: 來源或暫存驗證失敗

- **WHEN** 來源缺少 `init.lua`、目標型態不安全或暫存副本不完整
- **THEN** 部署 SHALL 非零停止，且 SHALL 保留原目標
