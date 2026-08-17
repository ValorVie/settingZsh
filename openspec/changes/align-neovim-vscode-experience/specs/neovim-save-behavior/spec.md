## Purpose

定義跨平台可預期的 Neovim 儲存行為，在維持 format-on-save 的同時尊重 EditorConfig、Markdown 行尾語意與既有檔案格式。

## ADDED Requirements

### Requirement: Format-on-save 保持啟用

一般程式碼與文件 buffer SHALL 預設允許 LazyVim format-on-save；filetype 例外不得以關閉整個 autoformat 取代單一儲存規則。

#### Scenario: 一般程式碼格式化

- **WHEN** 使用者儲存有已選 formatter 的 Lua、Python、PHP 或 Web fixture
- **THEN** 對應 formatter SHALL 執行一次，且輸出 SHALL 保留 final newline

#### Scenario: 使用者暫時停用格式化

- **WHEN** 使用者透過既有 LazyVim format toggle 停用目前 buffer 或全域格式化
- **THEN** 儲存 SHALL 不執行 formatter，重新啟用後 SHALL 恢復

### Requirement: EditorConfig 優先

有效的專案 `.editorconfig` SHALL 優先於個人縮排、EOL、final newline 與 trailing-whitespace fallback。

#### Scenario: 專案指定不同縮排

- **WHEN** `.editorconfig` 對目前檔案指定不同於個人預設的 indent size
- **THEN** Neovim SHALL 使用專案指定值

#### Scenario: 專案指定 EOL

- **WHEN** `.editorconfig` 指定 LF 或 CRLF
- **THEN** 儲存 SHALL 使用指定 EOL，不得由全域 Unix 預設強制改寫

### Requirement: Markdown 保留有語意的行尾空白

Markdown buffer SHALL 保持 formatter 可用，並 SHALL 在儲存時保留代表硬換行的兩個行尾空白。

#### Scenario: Markdown hard break

- **WHEN** Markdown 行以兩個空白結尾
- **THEN** 儲存與 formatter 執行後 SHALL 保留該 hard break

#### Scenario: Markdown formatter 與 preview

- **WHEN** Markdown Extra 的 formatter 或 preview 已安裝
- **THEN** Markdown filetype 例外 SHALL 不阻止格式化或 preview 啟動

### Requirement: 一般文字清除行尾空白

未被 EditorConfig 或 filetype 例外停用的可寫文字 buffer SHALL 在儲存時清除行尾空白，且 SHALL 保留游標位置與搜尋狀態。

#### Scenario: 一般文字行尾空白

- **WHEN** 非 Markdown 文字 fixture 含行尾空白且專案未停用 trimming
- **THEN** 儲存後行尾空白 SHALL 被移除

#### Scenario: 非一般 Buffer

- **WHEN** buffer 是 terminal、help、prompt、nofile、唯讀或 binary
- **THEN** trailing-whitespace fallback SHALL 略過，不得修改內容

### Requirement: 編碼與既有格式不被靜默破壞

Neovim SHALL 以 UTF-8 與 final newline 作為新文字檔預設，但不得自動猜測後靜默轉換已存在的非 UTF-8 或平台特定檔案。

#### Scenario: 新的一般文字檔

- **WHEN** 建立沒有專案覆寫的新文字檔
- **THEN** SHALL 使用 UTF-8、final newline 與平台／filetype 可接受的 EOL

#### Scenario: 非 UTF-8 或特殊 Windows 檔案

- **WHEN** 檔案需要明確 code page、BOM 或 CRLF
- **THEN** SHALL 由 EditorConfig、filetype 設定或使用者明確命令決定，不得僅依內容猜測後覆寫
