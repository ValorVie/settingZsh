## 1. 回歸測試

- [x] 1.1 新增隔離測試，從 `setup_linux.sh` 與 `setup_mac.sh` 執行實際 `merge_config()`，驗證狀態碼 `0`、`1`、`2` 的對應結果
- [x] 1.2 在修改 setup 前執行新測試，確認狀態碼 `2` 可重現失敗

## 2. Unix setup 修正

- [x] 2.1 修改 `setup_linux.sh`，把配置合併狀態碼 `0` 與 `2` 正規化為成功，其他狀態原樣回傳
- [x] 2.2 對 `setup_mac.sh` 套用相同行為，維持兩平台一致

## 3. 驗證

- [x] 3.1 執行新增回歸測試與完整 Python 測試
- [x] 3.2 對 `setup_linux.sh`、`setup_mac.sh` 與直接相關測試執行 Bash 語法檢查及 ShellCheck
- [x] 3.3 執行 OpenSpec strict validation，確認 change artifacts 與實作一致
