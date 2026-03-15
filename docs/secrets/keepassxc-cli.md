# keepassxc-cli 指南

這份指南的範圍是 **desktop file secret**，不是 runtime secret 注入架構。

目前建議用途：

- 管理不適合放在 public repo 的檔案型 secret
- 手動取值後放進 `custom private repo`
- 在 macOS / Windows 的桌面環境中做 file secret 管理

## 適用情境

- 你已經在用 KeePassXC
- 你有同步中的 `.kdbx` 資料庫
- 你要管理 SSH key、憑證、私有設定檔
- 你不打算在這一輪把 secret runtime 注入系統一起做完

## 安裝

### macOS

```bash
brew install --cask keepassxc
```

### Windows

- 使用官方安裝包或既有的 KeePassXC 安裝
- `keepassxc-cli` 會隨主程式一起提供

## 基本用法

列出指令：

```bash
keepassxc-cli --help
```

顯示某筆資料：

```bash
keepassxc-cli show <database.kdbx> <entry-path>
```

只取特定欄位：

```bash
keepassxc-cli show -a Password <database.kdbx> <entry-path>
```

## 建議資料結構

可以把與 `settingZsh` 相關的 file secret 分成：

- `ssh/<machine>/id_ed25519`
- `ssh/<machine>/id_ed25519.pub`
- `ssh/<machine>/config.d/90-private.conf`

這樣未來要放進 `custom private repo` 時比較好整理。

## 和本專案的關係

這個專案目前沒有直接從 `keepassxc-cli` 自動拉值寫進 `.zshrc`。

建議做法是：

1. 用 KeePassXC 保存 file secret
2. 將需要落地的 SSH 檔案放進你的 `custom private repo`
3. 由你的私有流程部署到 `~/.ssh/**`

## 不建議的做法

- 不要把 API token 直接塞進 `.zshrc`
- 不要把 runtime secret 設計和 file secret 管理混成同一套流程
- 不要讓 public repo 直接擁有 KeePassXC 資料庫或 master password
