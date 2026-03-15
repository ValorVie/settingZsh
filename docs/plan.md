# 歷史文件：舊版配置檔合併計畫

這份文件描述的是 **pre-chezmoi 時期** 的 `.zshrc` / `.vimrc` 合併設計，保留用途是解釋 `lib/config_merge.py` 與 legacy marker 的歷史來源，**不是目前版本的操作指南**。

## 目前版本請看哪裡

- `README.md`
  - 安裝、使用、feature flags、SSH overlay
- `docs/architecture.md`
  - dotfiles / `chezmoi` 原理與目前架構
- `docs/plans/2026-03-15-settingzsh-chezmoi-migration-design.md`
  - `chezmoi` 遷移設計背景

## 這份舊文件和目前實作的關係

- 新安裝與日常更新現在以 `chezmoi` 為主
- `.zshrc` 不再走整份 merge 模型
- `lib/config_merge.py` 目前主要保留給：
  - `.vimrc` merge
  - 舊版 `settingZsh:*` marker 遷移相容路徑

如果你要理解目前版本，請不要把這份文件當成現行規格。
