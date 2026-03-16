# valor-ssh-key

這是一個 `custom private repo` 範本，只示範 SSH 私有資料的 repo 結構，不示範公開 baseline，也不包含真正私鑰。

## 目標

- 只管理 private SSH material
- 不接管 `~/.ssh/config` 主檔
- 分離 `shared`、`shared-keys`、機器專屬 `config/keys/custom-paths`
- 以 `SOPS + age` 管理密文與 recipient

## 建議結構

```text
.
├── .sops.yaml.example
├── shared/
│   └── config.d/
│       └── 10-common-private.conf
├── shared-keys/
│   └── keys/
│       └── README.md
├── macmini/
│   ├── config.d/
│   │   └── 90-private.conf
│   ├── keys/
│   │   └── .keep
│   └── custom-paths/
│       └── sympasoft-macmini-ssh/
│           └── .keep
└── valorpc/
    ├── config.d/
    │   └── 90-private.conf
    ├── keys/
    │   └── .keep
    └── custom-paths/
        └── windows-imported/
            └── .keep
```

## 你應該怎麼用這個範本

1. 建立你自己的 private repo
2. 複製這個目錄內容到新 repo
3. 填入 machine-specific `config.d/90-private.conf`
4. 將 private keys 依 `standard path` 或 `custom-paths` 分類
5. 套用 `.sops.yaml` 規則後再 push
6. 用你自己的安全流程交付到目標機器

## 你不應該放進這個 repo 的東西

- `~/.ssh/config`
- `known_hosts`
- shell 設定
- git 設定
- editor 設定
- 其他和 SSH 無關的 secrets

## 路徑模型

- `standard path`：`~/.ssh/<key>`
- `custom-paths`：例如 `~/.ssh/config/sympasoft-macmini-ssh/<key>`

## `shared-keys` 說明

`shared-keys` 是顯式保留給例外情境的共享 key 區，預設應為空或只留 README。

## 範例設定檔

- `shared/config.d/10-common-private.conf`
- `macmini/config.d/90-private.conf`
- `valorpc/config.d/90-private.conf`

## 安全提醒

- 這個範本故意不附真正私鑰
- private repo 請至少使用 `SOPS + age`
- 建議保留 `owner` + `recovery` 兩組 recipient
