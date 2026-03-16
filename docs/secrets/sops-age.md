# SOPS + age 指南

這份文件定義 `custom private SSH repo` 的檔案加密做法。

## 範圍

- 適用：SSH file secret（private keys、private host config）
- 不適用：runtime secret 注入

## 核心原理

- `SOPS` 負責檔案級加密與 metadata
- `age` 負責 recipient 加解密
- private repo 只存密文，不存明文私鑰

## 路徑模型

- `standard path`
  - `~/.ssh/<key>`
- `custom managed path`
  - 例如 `~/.ssh/config/sympasoft-macmini-ssh/<key>`

兩種路徑都可加密後進 private repo，但需要在結構上分開管理。

## Recipient 模型

第一版建議固定兩組 recipient：

- `owner`
- `recovery`

先不要預設做 per-machine recipient matrix；有明確需求再擴充。

## `.sops.yaml` 範例

```yaml
creation_rules:
  - path_regex: ^shared/.*$
    age:
      - age1-owner-public-key
      - age1-recovery-public-key
  - path_regex: ^shared-keys/.*$
    age:
      - age1-owner-public-key
      - age1-recovery-public-key
  - path_regex: ^macmini/.*$
    age:
      - age1-owner-public-key
      - age1-recovery-public-key
  - path_regex: ^valorpc/.*$
    age:
      - age1-owner-public-key
      - age1-recovery-public-key
```

## Authoring 與落地

1. 在可信任工作機用 `sops` 編輯密文檔
2. 提交密文到 private repo
3. 只解密目標機器需要的檔案
4. 落地到 `~/.ssh/` 或 custom path
5. 檢查權限與 `ssh -G <host>`

## Key 管理

- recipient 變更：`sops updatekeys`
- 懷疑金鑰洩漏或需要重加密：`sops rotate`
- 保留離線 recovery key，避免 owner key 單點風險
