# gopass 指南

這份指南的範圍是 **server file secret** 與 CLI-first secret 管理，不是 runtime secret 注入抽象。

目前建議用途：

- Linux server / headless 環境
- local-first secret store
- 管理 SSH key、私有 config、憑證等 file secret

## 為什麼是 gopass

對 server 來說，`gopass` 比 GUI 型管理器更接近實際操作方式：

- CLI-first
- local-first
- 支援 Git / GPG 工作流
- 適合 headless 環境

## 安裝

### macOS

```bash
brew install gopass
```

### Linux

以你的發行版套件來源為主；若沒有，也可以用 release binary 或官方提供方式安裝。

安裝後至少確認：

```bash
gopass version
gpg --version
```

## 初始化

先準備 GPG key，然後：

```bash
gopass setup
```

或用明確 recipient 初始化：

```bash
gopass init <gpg-recipient>
```

## 基本用法

新增 secret：

```bash
gopass insert ssh/server-a/id_ed25519
```

查看 secret：

```bash
gopass show ssh/server-a/id_ed25519
```

編輯 secret：

```bash
gopass edit ssh/server-a/config.d/90-private.conf
```

## 和本專案的關係

本專案目前對 `gopass` 的定位是：

- 作為 server file secret 的推薦來源
- 幫助你維持 `custom private repo` 之外的原始秘密材料
- 不直接把 runtime secret 注入 `~/.zshrc`

建議流程：

1. 用 `gopass` 管理原始 file secret
2. 把需要落地到機器的 SSH 檔案整理成 `custom private repo`
3. 由你的私有部署流程把 `.ssh/**` 放到目標機器

## 建議目錄命名

- `ssh/<host>/id_ed25519`
- `ssh/<host>/id_ed25519.pub`
- `ssh/<host>/config.d/90-private.conf`

## 不建議的做法

- 不要把 `gopass` store 當成 public dotfiles repo 的一部分
- 不要把 runtime token 直接 render 進 `.zshrc`
- 不要把 `known_hosts` 當成需要同步的 secret material
