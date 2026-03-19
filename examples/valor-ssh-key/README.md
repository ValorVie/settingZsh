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

### 建立 private repo（做一次）

1. 建立你自己的 private repo
2. 複製這個目錄內容到新 repo
3. 設定 `.sops.yaml`（見下方「SOPS + age 使用方式」步驟 2–3）
4. 填入 machine-specific `config.d/90-private.conf`
5. 將 private keys 放入對應的 `keys/` 或 `custom-paths/`
6. 用 `sops encrypt -i` 加密所有私鑰後再 push

### 部署到目標機器（每台機器做一次）

公開的 chezmoi baseline **不會**自動拉取或解密 private repo，以下步驟需手動執行：

```bash
# 1. 確認目標機器上有 sops 和 age
brew install sops age   # 或用你的套件管理器

# 2. 準備 age private key（見步驟 7 的情境 A 或 B）
mkdir -p ~/.config/sops/age
chmod 700 ~/.config/sops/age
# 將 owner.txt 透過安全管道傳到 ~/.config/sops/age/owner.txt
chmod 600 ~/.config/sops/age/owner.txt
export SOPS_AGE_KEY_FILE=~/.config/sops/age/owner.txt

# 3. Clone private repo
git clone <your-private-repo> ~/tmp/ssh-private
cd ~/tmp/ssh-private

# 4. 解密這台機器的私鑰（以 macmini 為例）
find macmini/keys -type f ! -name '.keep' -exec sops decrypt -i {} \;

# 5. 部署到 ~/.ssh
cp macmini/keys/* ~/.ssh/
chmod 600 ~/.ssh/id_ed25519*   # 確保私鑰權限正確

# 6. 部署 config 片段到 ~/.ssh/config.d/
cp macmini/config.d/90-private.conf ~/.ssh/config.d/
cp shared/config.d/10-common-private.conf ~/.ssh/config.d/

# 7. 部署 custom-paths（如有）
cp -r macmini/custom-paths/sympasoft-macmini-ssh ~/.ssh/config/

# 8. 清理
rm -rf ~/tmp/ssh-private

# 9. 驗證
ssh -T git@github.com   # 或其他你設定的 Host
```

> **注意**：解密後的明文私鑰只存在目標機器的 `~/.ssh/` 裡，不要提交回 repo。private repo 裡永遠保持加密狀態。

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

## `keys/` 目錄說明

`keys/` 放的是 SSH 私鑰檔案，對應 `config.d/*.conf` 裡的 `IdentityFile`。例如 `macmini/config.d/90-private.conf` 中：

```
Host github-work
  IdentityFile ~/.ssh/id_ed25519_work
```

那麼 `macmini/keys/` 裡就應該放 `id_ed25519_work`（以及對應的 `.pub`，如需要）：

```text
macmini/
├── config.d/
│   └── 90-private.conf        # 引用 ~/.ssh/id_ed25519_work
└── keys/
    ├── id_ed25519_work         # ← 私鑰本體，push 前必須用 SOPS 加密
    └── id_ed25519_work.pub     # ← 公鑰（選擇性，不需要加密）
```

部署到目標機器時，`keys/` 裡的檔案會放到 `IdentityFile` 指定的路徑（通常是 `~/.ssh/`）。

若私鑰不在 standard path 而是放在自訂路徑（如 `~/.ssh/config/sympasoft-macmini-ssh/`），則改放到 `custom-paths/` 對應的子目錄裡。

> **重要**：`keys/` 裡的私鑰在 `git add` 之前必須先用 SOPS 加密（見下方「SOPS + age 使用方式」步驟 4）。絕對不要提交明文私鑰。

## 範例設定檔

- `shared/config.d/10-common-private.conf`
- `macmini/config.d/90-private.conf`
- `valorpc/config.d/90-private.conf`

## SOPS + age 是什麼

- **[SOPS](https://github.com/getsops/sops)**（Secrets OPerationS）是 Mozilla 開發的加密檔案編輯器。它可以加密 YAML、JSON、ENV、INI 及二進位檔案，且只加密 value 不加密 key，讓加密後的檔案仍可透過 `git diff` 審查結構變動。SOPS 本身不綁定特定加密後端，支援 age、AWS KMS、GCP KMS、Azure Key Vault 及 PGP。
- **[age](https://github.com/FiloSottile/age)**（讀作 /aɡe/，如義大利語）是一套現代、簡潔的檔案加密工具，設計目標是取代 GPG。一個 age 金鑰對只有一行 public key 和一行 private key，沒有信任網、沒有設定檔、沒有子金鑰，極度容易備份與管理。

在本範本中，**SOPS 負責「加解密流程」，age 負責「金鑰管理」**。兩者搭配的好處：

- 不需要 GPG keyring，金鑰就是一個純文字檔
- 支援多 recipient（多人 / 多機器共享同一份密文）
- `.sops.yaml` 以路徑規則自動套用正確的 recipient，不需每次手動指定

## SOPS + age 使用方式

### 1. 安裝

```bash
# macOS
brew install sops age

# Linux (Debian/Ubuntu)
sudo apt install age
# SOPS 從 GitHub Releases 下載：https://github.com/getsops/sops/releases
```

### 2. 產生 age 金鑰對

建議至少產生 `owner`（日常使用）和 `recovery`（備援）兩組：

```bash
# owner key
age-keygen -o ~/.config/sops/age/owner.txt
# 終端機會印出類似這樣的訊息：
#   Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p

# recovery key（離線保管）
age-keygen -o ~/safe-place/recovery.txt
```

`age-keygen` 產生的檔案內容長這樣：

```text
# created: 2026-03-19T10:00:00+08:00
# public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

- 第 2 行的 `public key:` 註解 → 複製到 `.sops.yaml` 裡，用於**加密**
- 第 3 行的 `AGE-SECRET-KEY-...` → 這就是 **private key**，用於**解密**，留在本機不要外流

整理一下兩把 key 的角色：

| | public key (`age1...`) | private key (`AGE-SECRET-KEY-...`) |
|---|---|---|
| 存在哪 | `.sops.yaml`（提交到 repo） | `~/.config/sops/age/owner.txt`（只留本機） |
| 誰用 | SOPS 加密時讀取 | SOPS 解密時讀取 |
| 可以公開嗎 | 可以，它只能加密不能解密 | **絕對不行** |

如果事後忘了 public key，可以從 key 檔案的註解查回：

```bash
grep 'public key' ~/.config/sops/age/owner.txt
```

### 3. 設定 `.sops.yaml`

`.sops.yaml` 是 SOPS 的**規則檔**，告訴 SOPS：「加密某個路徑下的檔案時，要用哪些 age public key 當 recipient」。有了它，你執行 `sops encrypt` 時不需要手動指定 `--age` 參數——SOPS 會自動根據檔案路徑匹配規則。

複製範本並填入步驟 2 取得的 public key：

```bash
cp .sops.yaml.example .sops.yaml
```

打開 `.sops.yaml`，將所有 `age1-owner-public-key` 替換為 owner 的 public key，`age1-recovery-public-key` 替換為 recovery 的 public key。例如：

```yaml
creation_rules:
  # 當檔案路徑符合 ^macmini/.*$ 時，用以下 public key 加密
  - path_regex: ^macmini/.*$
    age:
      - age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p  # owner
      - age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # recovery
```

這表示：只要持有 owner 或 recovery 其中一把 private key 的人，都能解密 `macmini/` 下的檔案。

### 4. 加密檔案

有了 `.sops.yaml`，直接對檔案執行加密即可——SOPS 會自動查找 `.sops.yaml`，根據檔案路徑決定用哪些 recipient：

```bash
# 加密單一檔案（SOPS 看到路徑是 macmini/...，自動套用 macmini 的規則）
sops encrypt -i macmini/keys/id_ed25519

# 加密整個目錄下的 key 檔案
find macmini/keys -type f ! -name '.keep' -exec sops encrypt -i {} \;
```

> 如果沒有 `.sops.yaml`，你就必須每次手動指定：`sops encrypt --age age1ql3z...,age1xxx... -i macmini/keys/id_ed25519`——路徑規則就是為了省掉這件事。

### 5. 解密檔案

SOPS 需要知道你的 private key 位置：

```bash
# 設定環境變數（加到 shell profile）
export SOPS_AGE_KEY_FILE=~/.config/sops/age/owner.txt

# 解密檢視（不改檔案）
sops decrypt macmini/keys/id_ed25519

# 就地解密
sops decrypt -i macmini/keys/id_ed25519
```

### 6. 編輯已加密檔案

```bash
sops macmini/keys/id_ed25519
# 會開啟編輯器，存檔後自動重新加密
```

> **注意**：`.sops.yaml` 本身不需要加密，它只定義加密規則。但 `.sops.yaml` 中的 public key 不算機密，可以安全提交到 repo。

### 7. 在其他機器上解密（多機器使用）

SOPS + age 的設計支援多機器、多人協作。加密後的 repo 可以 clone 到任何機器上，只要該機器持有其中一把 recipient 的 private key 就能解密。

**情境 A：用同一把 owner key（適合個人多機器）**

把 owner 的 private key 檔案透過安全管道（如 USB、`scp`、密碼管理器）複製到目標機器：

```bash
# 在目標機器上（以你自己的使用者帳號執行，不是 root）
mkdir -p ~/.config/sops/age
# 透過安全方式將 owner.txt 傳到這裡
chmod 600 ~/.config/sops/age/owner.txt   # user 600，擁有者是你的使用者帳號
chmod 700 ~/.config/sops/age             # 目錄也鎖住

export SOPS_AGE_KEY_FILE=~/.config/sops/age/owner.txt
git clone <your-private-repo>
sops decrypt -i macmini/keys/id_ed25519
```

**情境 B：每台機器各自一把 key（適合團隊或更嚴格的隔離）**

在目標機器上產生獨立的 age 金鑰對，然後把新的 public key 加入 `.sops.yaml` 作為額外的 recipient：

```bash
# 在目標機器上產生 key
age-keygen -o ~/.config/sops/age/this-machine.txt
# 記下印出的 public key: age1newmachine...
```

回到管理機器，將新 public key 加入 `.sops.yaml`：

```yaml
creation_rules:
  - path_regex: ^macmini/.*$
    age:
      - age1ql3z...   # owner
      - age1xxx...     # recovery
      - age1newmachine...  # 新增的機器
```

然後用 `sops updatekeys` 重新加密，讓已存在的密文也納入新 recipient：

```bash
# 對所有已加密檔案更新 recipient 列表
find macmini/keys -type f ! -name '.keep' -exec sops updatekeys {} \;
git add -A && git commit -m "chore: add new machine recipient"
```

這樣新機器 clone 後就能用自己的 private key 解密，不需要拿到 owner 的 private key。

> **總結**：加密只需要 public key（在 `.sops.yaml` 裡），解密需要對應的 private key（在本機的 `SOPS_AGE_KEY_FILE`）。只要 `.sops.yaml` 有列入你的 public key，你就能解密。這就是為什麼建議至少保留 owner + recovery 兩組——即使 owner key 遺失，recovery key 還能救回資料。

## 安全提醒

- 這個範本故意不附真正私鑰
- private repo 請至少使用 `SOPS + age`
- 建議保留 `owner` + `recovery` 兩組 recipient
- age private key 檔案（`owner.txt`、`recovery.txt`）絕對不能提交到任何 repo
