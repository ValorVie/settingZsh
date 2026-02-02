## ADDED Requirements

### Requirement: Section Markers 標記管理區段

合併引擎 SHALL 使用成對的 begin/end markers 標記每個 managed section。Marker 格式依檔案類型而異：

| 檔案類型 | begin marker | end marker |
|----------|-------------|------------|
| zsh | `# === settingZsh:managed:<section-id>:begin ===` | `# === settingZsh:managed:<section-id>:end ===` |
| vim | `" === settingZsh:managed:<section-id>:begin ===` | `" === settingZsh:managed:<section-id>:end ===` |

#### Scenario: zsh 檔案的 markers
- **WHEN** 合併引擎處理 `--type zsh` 的檔案
- **THEN** markers SHALL 使用 `#` 作為註解字元

#### Scenario: vim 檔案的 markers
- **WHEN** 合併引擎處理 `--type vim` 的檔案
- **THEN** markers SHALL 使用 `"` 作為註解字元

### Requirement: User Section 標記使用者自訂區段

合併引擎 SHALL 使用 `settingZsh:user:begin` / `settingZsh:user:end` markers 標記使用者自訂區段。User section 位於所有 managed sections 之後。

#### Scenario: user section 存在
- **WHEN** 目標檔案包含 user section markers
- **THEN** 合併引擎 SHALL 保留 user section 內的所有內容不做修改

### Requirement: 全新安裝時寫入完整結構

當目標檔案不存在或為空檔案時，合併引擎 SHALL 寫入 managed section（含 markers 和模板內容）以及空的 user section。

#### Scenario: 目標檔案不存在
- **WHEN** `--target` 指定的檔案不存在
- **THEN** 合併引擎 SHALL 建立檔案，寫入 managed section markers + 模板內容 + 空 user section markers
- **THEN** 回傳碼 SHALL 為 `2`

#### Scenario: 目標檔案為空
- **WHEN** `--target` 指定的檔案存在但內容為空
- **THEN** 合併引擎 SHALL 等同全新安裝處理

### Requirement: 已有 Markers 時更新 Managed 段

當目標檔案已包含對應 section 的 markers 時，合併引擎 SHALL 僅替換該 managed section 的內容，不觸碰 user section 和其他 managed sections。

#### Scenario: 重複執行更新
- **WHEN** 目標檔案已包含 `settingZsh:managed:<section-id>:begin` 和 `end` markers
- **THEN** 合併引擎 SHALL 將該 markers 之間的內容替換為最新模板內容
- **THEN** user section 內容 SHALL 保持不變

#### Scenario: 同一檔案多個 managed sections
- **WHEN** 目標檔案包含 `zsh-base` 和 `editor` 兩個 managed sections
- **THEN** 合併引擎 SHALL 僅更新 `--section` 指定的 section，不影響其他 section

### Requirement: 無 Markers 時執行首次升級合併

當目標檔案存在且有內容但無 markers 時，合併引擎 SHALL 備份原檔、執行去重比對、輸出合併結果。

#### Scenario: 首次升級流程
- **WHEN** 目標檔案存在且有內容但不包含任何 settingZsh markers
- **THEN** 合併引擎 SHALL 備份原檔為 `<target>.bak.<timestamp>`
- **THEN** SHALL 將原檔全部內容視為使用者內容
- **THEN** SHALL 逐行正規化比對，找出與模板重複的行
- **THEN** SHALL 輸出 managed section + 去重後的使用者獨有行（放入 user section）

#### Scenario: end marker 被刪除
- **WHEN** 目標檔案包含 begin marker 但缺少對應的 end marker
- **THEN** 合併引擎 SHALL 視為無 markers，走首次升級流程

### Requirement: 正規化去重比對

合併引擎 SHALL 對使用者行和模板行進行正規化後比對，識別重複行。

正規化規則：
1. 去除前後空白
2. 多空白壓縮為單一空白
3. 純註解行和空行 SHALL 不參與比較

#### Scenario: 完全重複行
- **WHEN** 使用者行正規化後與模板行完全一致
- **THEN** 合併引擎 SHALL 移除使用者版，在差異摘要中列出

#### Scenario: 使用者獨有行
- **WHEN** 使用者行正規化後未出現在模板中
- **THEN** 合併引擎 SHALL 保留該行至 user section

### Requirement: Vim set 命令語義比對

對 `--type vim` 的檔案，合併引擎 SHALL 對 `set` 命令提取 key 做語義比對。

#### Scenario: 值衝突
- **WHEN** 使用者有 `set tabstop=2` 且模板有 `set tabstop=4`
- **THEN** 合併引擎 SHALL 保留使用者版（`set tabstop=2`）至 user section
- **THEN** 差異摘要 SHALL 列出此衝突

#### Scenario: 完全重複的 set 命令
- **WHEN** 使用者和模板都有 `set number`
- **THEN** 合併引擎 SHALL 移除使用者版，在差異摘要中列出

### Requirement: 差異摘要輸出

每次合併完成後，合併引擎 SHALL 輸出差異摘要至 stdout，包含：管理區段寫入狀態、移除的重複行數與內容、保留的自訂行數、值衝突清單、備份檔案路徑（若有）。

#### Scenario: 首次升級的差異摘要
- **WHEN** 執行首次升級合併
- **THEN** 差異摘要 SHALL 列出移除的重複行具體內容
- **THEN** SHALL 列出保留的自訂行數
- **THEN** SHALL 列出備份檔案路徑

#### Scenario: 重複執行的差異摘要
- **WHEN** 執行已有 markers 的更新
- **THEN** 差異摘要 SHALL 顯示管理區段已更新

#### Scenario: dry-run 模式
- **WHEN** 使用 `--dry-run` 選項執行
- **THEN** 合併引擎 SHALL 僅輸出差異摘要，不寫入任何檔案

### Requirement: CLI 介面

合併引擎 SHALL 提供以下 CLI 選項：

| 選項 | 必填 | 說明 |
|------|------|------|
| `--target` | 是 | 目標檔案路徑 |
| `--template` | 是 | 模板檔案路徑 |
| `--section` | 是 | section ID |
| `--type` | 是 | 檔案類型（`zsh` 或 `vim`） |
| `--dry-run` | 否 | 僅輸出摘要 |
| `--no-color` | 否 | 無色彩輸出 |

回傳碼：`0` 成功、`1` 錯誤、`2` 全新安裝。

#### Scenario: 必填選項缺失
- **WHEN** 缺少任一必填選項
- **THEN** 合併引擎 SHALL 輸出使用說明並以回傳碼 `1` 退出

#### Scenario: 模板檔案不存在
- **WHEN** `--template` 指定的檔案不存在
- **THEN** 合併引擎 SHALL 輸出錯誤訊息並以回傳碼 `1` 退出
