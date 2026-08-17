## Purpose

提供跨平台一致的 Neovim 工作區導航，讓找檔、全文搜尋、檔案總管、最近專案與路徑複製使用同一組根目錄與排除語意。

## ADDED Requirements

### Requirement: 單一 Picker 與 Explorer 後端

Neovim 配置 SHALL 明確指定一組主要 picker 與 explorer，不得因 LazyVim install version 或舊 lockfile 而切換到不同後端。

#### Scenario: 新舊安裝行為一致

- **WHEN** 相同配置分別部署到全新與既有 Neovim data directory
- **THEN** 找檔、全文搜尋、最近專案與 explorer SHALL 使用相同的主要後端

#### Scenario: 核心導航快捷鍵

- **WHEN** 使用者操作 `<Leader>ff`、`<Leader>/`、`<Leader>e` 或 `<Leader>fp`
- **THEN** 對應功能 SHALL 分別執行找檔、全文搜尋、檔案總管與最近專案切換

### Requirement: 統一搜尋與 Explorer 排除

主要 picker 與 explorer SHALL 共用一般依賴、建置輸出、快取與版本控制目錄的排除意圖；專案自己的 ignore 檔 SHALL 繼續生效。

#### Scenario: 預設隱藏大型產物目錄

- **WHEN** fixture 包含 `node_modules`、`vendor`、`target`、`dist`、`build`、`.git` 或快取目錄
- **THEN** 預設找檔、grep 與 explorer SHALL 不顯示這些項目

#### Scenario: 暫時顯示 ignored 項目

- **WHEN** 使用者啟用 picker 或 explorer 的 ignored toggle
- **THEN** 被忽略項目 SHALL 可在本次操作中顯示，且不得永久改寫專案 ignore 檔

#### Scenario: 不追蹤符號連結

- **WHEN** 搜尋根目錄含指向其他樹的符號連結
- **THEN** 預設找檔與 grep SHALL 不遞迴追蹤該連結

### Requirement: 最近專案與 Session 恢復

Neovim SHALL 以實際開啟過的專案根目錄提供最近專案清單，並 SHALL 使用既有 session 能力恢復工作狀態；不得為建立清單而週期性遞迴掃描整個使用者 home。

#### Scenario: 最近專案切換

- **WHEN** 使用者開啟多個 Git 專案後執行專案 picker
- **THEN** picker SHALL 列出最近使用的專案根目錄並允許切換

#### Scenario: 恢復專案 Session

- **WHEN** 使用者重新進入有已儲存 session 的專案
- **THEN** SHALL 可恢復該專案的 buffers 與視窗配置

### Requirement: 路徑複製語意

Neovim SHALL 分別提供絕對路徑、專案相對路徑與專案相對 `path:line` 複製，且 SHALL 寫入 `+` register 以配合已設定的 clipboard provider。

#### Scenario: Explorer 複製絕對路徑

- **WHEN** 使用者在 explorer 對檔案執行絕對路徑快捷鍵
- **THEN** `+` register SHALL 收到正規化的絕對路徑

#### Scenario: Explorer 複製專案相對路徑

- **WHEN** 使用者在 explorer 對專案內檔案執行相對路徑快捷鍵
- **THEN** `+` register SHALL 收到以專案 root 為基準、使用 `/` 分隔的相對路徑

#### Scenario: Buffer 複製相對路徑與行號

- **WHEN** 使用者在有檔名的普通 buffer 執行 `path:line` 快捷鍵
- **THEN** `+` register SHALL 收到 `<relative-path>:<current-line>`

#### Scenario: 無法相對化

- **WHEN** 目標不在偵測到的專案 root 下
- **THEN** SHALL 回退為正規化絕對路徑

#### Scenario: Buffer 無檔名

- **WHEN** 目前 buffer 沒有檔名
- **THEN** SHALL 顯示提示並停止，不得覆寫 `+` register
