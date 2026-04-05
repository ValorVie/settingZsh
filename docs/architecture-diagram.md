# settingZsh 架構圖

這份文件只做一件事：用圖把目前 `settingZsh` 的控制面、資料流與責任邊界畫清楚。

若你要看詳細文字說明，請回到 [architecture.md](./architecture.md)。
若你不熟圖裡的英文術語，先看 [terminology.md](./terminology.md)。

## 總覽

```mermaid
flowchart TB
    subgraph Repo["Git Repo: settingZsh"]
        Root["repo root"]
        RootFile[".chezmoiroot -> home/"]
        Source["home/\n來源目錄"]
        Lib["lib/settingzsh legacy guardrails"]
        Docs["docs/*.md"]
        Root --> RootFile --> Source
        Root --> Lib
        Root --> Docs
    end

    subgraph Public["公開基線設定"]
        Config["home/.chezmoi.toml.tmpl\n功能開關 / 機器資料"]
        External["home/.chezmoiexternal.toml.tmpl\nprivate repo 外部來源"]
        Modify["home/modify_dot_zshrc\nbootstrap 擁有權"]
        Shell["managed.d/*.zsh.tmpl"]
        PS["PowerShell profiles"]
        SSH["private_dot_ssh/config.tmpl\nconfig.d/10-common.conf.tmpl"]
        Scripts["run_once_* / run_onchange_*"]
        Config --> Scripts
        External --> Scripts
        Modify --> Shell
    end

    subgraph Target["目標家目錄中的實際檔案"]
        Zshrc["~/.zshrc\n單一 bootstrap 區塊"]
        Init["~/.config/settingzsh/init.zsh"]
        Managed["~/.config/settingzsh/managed.d/*"]
        Profiles["~/Documents/*/Microsoft.PowerShell_profile.ps1"]
        SSHMain["~/.ssh/config"]
        SSHDir["~/.ssh/config.d/*"]
        Tools["字型 / zinit / 套件 / editor 工具"]
        CustomPaths["~/.ssh/custom-paths/*"]
    end

    subgraph Private["自訂私有 repo"]
        PrivateRepo["git repo\nshared/ shared-keys/ <profile>/"]
        OverlayCheckout["~/.local/share/settingzsh/private-ssh-overlay"]
        PrivateRepo --> OverlayCheckout
    end

    subgraph Legacy["Legacy / Adoption Guardrails"]
        Preflight["preflight"]
        Adopt["adopt"]
        Migrate["migrate"]
        Reconcile["reconcile"]
        Doctor["doctor"]
    end

    Source --> Public
    Public --> Target
    OverlayCheckout --> Scripts
    Scripts --> Tools
    Scripts --> SSHDir
    Scripts --> CustomPaths
    Modify --> Zshrc
    Shell --> Managed
    PS --> Profiles
    SSH --> SSHMain
    SSH --> SSHDir
    Lib --> Legacy
    Legacy --> Zshrc
    Legacy --> Init
    Legacy --> Managed
```

## 新機器首次安裝流程

```mermaid
sequenceDiagram
    participant U as User
    participant C as chezmoi
    participant P as 公開基線設定
    participant X as Private SSH 覆蓋層
    participant H as 使用者家目錄

    U->>C: chezmoi init --apply <public-repo>
    C->>P: 讀取 home/ 來源目錄
    P->>H: 寫入 ~/.zshrc / init.zsh / profiles / ~/.ssh/config
    P->>H: 執行基礎套件 / zinit / 字型 / editor 腳本
    alt private_ssh_overlay = true
        C->>X: clone private repo 外部來源
        X->>H: 寫入 ~/.ssh/config.d / ~/.ssh/* / ~/.ssh/custom-paths/*
    else private_ssh_overlay = false
        X-->>H: 略過覆蓋層
    end
```

## `.zshrc` 擁有權模型

```mermaid
flowchart LR
    Existing["既有 ~/.zshrc"] --> Modify["modify_dot_zshrc"]
    Empty["空白或不存在 ~/.zshrc"] --> Modify
    Modify --> Canonical["正規化成單一 bootstrap"]
    Canonical --> Target["~/.zshrc"]
    Target --> Init["~/.config/settingzsh/init.zsh"]
    Init --> Managed["managed.d/*.zsh"]
    Init --> Local["local.d/*.zsh"]
```

## 邊界規則

- `public baseline` 是唯一主入口，負責非機密的公開基線設定。
- `custom private repo` 只負責 `~/.ssh/**`，不接管 `~/.ssh/config` 主檔。
- `legacy CLI` 只處理 adoption / migrate / reconcile，不再是新安裝主流程。
- `~/.zshrc` 只允許一個 `settingZsh bootstrap` 區塊；真正 shell 內容在 `init.zsh` 與 `managed.d/`。
