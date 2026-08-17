## Purpose

確保 Linux 與 macOS 安裝流程正確解讀配置合併工具的狀態碼，不會在全新配置成功寫入後誤判失敗並跳過後續安裝步驟。

## ADDED Requirements

### Requirement: Unix setup 正確處理配置合併狀態

Linux 與 macOS setup 腳本 SHALL 將配置合併工具的狀態碼 `0` 與 `2` 視為成功，並 SHALL 將其他非零狀態視為失敗。

#### Scenario: 一般合併成功

- **WHEN** 配置合併工具回傳狀態碼 `0`
- **THEN** setup SHALL 繼續執行下一個安裝步驟

#### Scenario: 全新配置建立成功

- **WHEN** 配置合併工具建立原本不存在或為空的目標檔案並回傳狀態碼 `2`
- **THEN** setup SHALL 保留已建立的配置並繼續執行下一個安裝步驟

#### Scenario: 配置合併失敗

- **WHEN** 配置合併工具回傳 `0` 與 `2` 以外的非零狀態碼
- **THEN** setup SHALL 以失敗狀態停止，不得把該結果改判為成功
