# README: Zsh + Zinit + FZF + Python 3.11

## 功能

- 安裝並設定 **Zsh** 為預設 Shell
- 安裝 **Python 3.11** 與 **pip**
- 安裝 **fzf**（模糊搜尋工具）
- 安裝 **zoxide**（快速目錄切換工具）
- 配置 **Zinit** 來管理 Zsh 插件
- 安裝並設定 **JetBrainsMono Nerd Font**
- 預設 Zsh 插件包含：
  - **Powerlevel10k**（高效能 Zsh 提示行）
  - **fzf-tab**（fzf 選單自動補全）
  - **zsh-syntax-highlighting**（語法高亮）
  - **zsh-autosuggestions**（命令建議）
  - 其他實用工具和命令片段

---

## 安裝步驟

1. 確保您的系統具備基礎工具：
   ```bash
   sudo apt update -y && sudo apt install -y zsh git xz-utils fontconfig
   ```

2. 切換預設 Shell 為 Zsh：
   ```bash
   chsh -s /bin/zsh "$(whoami)"
   ```

3. 下載並執行此腳本：
   ```bash
   chmod +x setup_env.sh
   ./setup_env.sh
   ```
4. 更新套件（可選）：
   ```bash
   chmod +x update.sh
   ./update.sh
   ```


---

## 腳本內容摘要

- **備份原有 Zsh 配置檔：** 若已有 `.zshrc`，會自動備份為 `.zshrc.bak`。
- **安裝必要工具：**
  - 安裝 **Python 3.11** 與 **pip**
  - 安裝 **fzf** 與 **zoxide**
  - 自動下載並安裝 **JetBrainsMono Nerd Font**
- **自動配置 Zsh 插件：**
  - 使用 **Zinit** 安裝和管理插件
  - 預設啟用高效能提示行（Powerlevel10k）
  - 提供多種實用的 Zsh 設定和快捷鍵

---

## 常見問題

1. **如何立即套用新設定？**
   執行以下指令：
   ```bash
   exec zsh
   ```

2. **如何確認 Zsh 是否為預設 Shell？**
   執行以下指令確認：
   ```bash
   echo $SHELL
   ```
   若回傳結果為 `/bin/zsh`，則表示已成功設為預設。

3. **字體安裝後沒有生效？**
   - 確認已重啟終端機。
   - 使用終端機的設定選項更改字體為 **JetBrainsMono Nerd Font**。

4. **如何進一步自訂 Zsh？**
   - 編輯 `~/.zshrc` 文件，自訂自己的配置。
   - 配置 **Powerlevel10k**，執行以下指令：
     ```bash
     p10k configure
     ```

---

## 注意事項

- **Root 使用者：** 若以 root 身份執行腳本，請手動修改 `~/.zshrc` 中的環境變數路徑。
- **重新登入：** 若切換 Shell 後未生效，請登出並重新登入。
## 更新套件

若要更新安裝的工具與字體，可執行：
```bash
./update.sh
```

