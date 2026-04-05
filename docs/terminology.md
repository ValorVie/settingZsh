# settingZsh 術語總表

這份文件是本專案所有英文術語的統一維護點。

規則如下：

- 使用者會讀到的文件，第一次出現英文術語時，優先寫「中文主詞（英文原詞）」。
- 若同一術語已在本文件定義，其他文件不應再各自發明不同中文譯法。
- 新增英文術語時，必須同步更新這份總表。

## 常用術語

| 英文術語 | 建議中文 | 說明 |
| --- | --- | --- |
| `baseline` | 基線設定 | 這份 repo 提供的預設共用設定。 |
| `public baseline` | 公開基線設定 | 放在 public repo、可直接分享的基線設定。 |
| `custom private repo` | 自訂私有 repo | 使用者自己維護、承載 SSH 私有資料的 repo。 |
| `bootstrap` | 啟動橋接區塊 | `~/.zshrc` 裡最小的一段入口，只負責接到 `~/.config/settingzsh/init.zsh`。 |
| `fresh install` | 新機器首次安裝 | 沒有既有重型 shell 生態時，直接 `chezmoi init --apply` 的流程。 |
| `existing machine` | 既有機器 | 已經有自己的 `.zshrc`、plugin manager、hook 或既有 shell 生態的機器。 |
| `adoption` | 導入 | 把既有機器安全接到 `settingZsh` 的流程。 |
| `adoption gate` | 導入關卡 | 用來判斷既有機器能不能直接套用、是否要先做檢查與報告的保護機制。 |
| `source state` | 來源目錄 | `chezmoi` 實際讀取的模板、腳本與檔案結構。 |
| `source root` | 來源根目錄 | `chezmoi` 真正拿來當來源起點的路徑。這個 repo 是 `home/`。 |
| `target state` | 目標檔案狀態 | 最後寫進使用者家目錄後的檔案狀態。 |
| `target path` | 目標路徑 | 檔案最終會落地到哪個家目錄路徑，例如 `~/.zshrc`。 |
| `materialize` | 寫入落地 | 把來源模板轉成真正存在於目標路徑的檔案或目錄。 |
| `overlay` | 覆蓋層 | 第二階段額外加上的 private SSH 資料層。 |
| `private SSH overlay` | private SSH 覆蓋層 | private repo checkout 後，同步到 `~/.ssh/**` 的第二階段資料層。 |
| `feature flag` | 功能開關 | 控制某段安裝或功能是否啟用的設定，例如 `feature_editor`。 |
| `profile` | 設定檔身分 | private SSH overlay 用來決定機器專屬資料夾的名稱，通常對應主機名。 |
| `fallback` | 備援安裝路徑 | 系統套件安裝失敗時，改走手動下載或替代安裝方式。 |
| `stub` | 橋接檔 | 本身不承載主要邏輯，只把流程轉接到真正主檔的輕量檔案。 |

## 專案內目前最常見的寫法

- 公開基線設定（`public baseline`）
- 自訂私有 repo（`custom private repo`）
- 啟動橋接區塊（`bootstrap`）
- 來源目錄（`source state`）
- 來源根目錄（`source root`）
- 目標檔案狀態（`target state`）
- 寫入落地（`materialize`）
- private SSH 覆蓋層（`private SSH overlay`）

## 維護提醒

- 若 README、架構文件、部署清單、導入指南首次出現新英文術語，請先補這份總表。
- 若同一術語有更好的中文譯名，請先改總表，再批次調整其他文件。
