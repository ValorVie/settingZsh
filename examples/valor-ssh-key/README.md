# valor-ssh-key

這是一個 `custom private repo` 範本，只示範 SSH 私有資料的 repo 結構，不示範公開 baseline，也不包含真正的私鑰。

## 目標

- 只管理 `.ssh/**`
- 不接管 `~/.ssh/config` 主檔
- 只補 `90-private.conf` 與 key files
- 保持和 public baseline 的 `config + config.d` 模型相容

## 建議結構

```text
.
└── .ssh/
    ├── config.d/
    │   └── 90-private.conf
    ├── id_ed25519.example
    └── id_ed25519.pub.example
```

## 你應該怎麼用這個範本

1. 建立你自己的 private repo
2. 複製這個目錄內容到新 repo
3. 把 `id_ed25519.example` / `id_ed25519.pub.example` 換成你真正要用的檔名
4. 編輯 `.ssh/config.d/90-private.conf`
5. 用你自己的安全流程交付到目標機器

## 你不應該放進這個 repo 的東西

- `~/.ssh/config`
- `known_hosts`
- shell 設定
- git 設定
- editor 設定
- 其他和 SSH 無關的 secrets

## 範例 `90-private.conf`

這個 repo 已內建一個可改寫的示範檔：

- `.ssh/config.d/90-private.conf`

## 安全提醒

- 這個範本故意不附真正私鑰
- 若你要把私鑰放進 private repo，請至少確保 repo 本身是 private，並考慮額外加密
- 如果你不想把私鑰直接放 repo，這個範本也可以只放 `90-private.conf`，key file 改由其他流程提供
