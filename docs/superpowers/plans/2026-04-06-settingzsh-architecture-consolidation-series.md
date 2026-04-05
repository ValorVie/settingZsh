# settingZsh Architecture Consolidation Plan Series

這份索引把 [架構大收斂設計](/home/valor/settingZsh/docs/superpowers/specs/2026-04-05-settingzsh-architecture-consolidation-design.md) 拆成 4 份可獨立合併的 implementation plans。

## 執行順序

1. [Plan 1: Canonical Schema and Consumers](/home/valor/settingZsh/docs/superpowers/plans/2026-04-06-settingzsh-plan-1-canonical-schema-and-consumers.md)
2. [Plan 2: Single Source Home and Bootstrap Utils](/home/valor/settingZsh/docs/superpowers/plans/2026-04-06-settingzsh-plan-2-single-source-home-and-bootstrap-utils.md)
3. [Plan 3: Legacy CLI Guardrails Only](/home/valor/settingZsh/docs/superpowers/plans/2026-04-06-settingzsh-plan-3-legacy-cli-guardrails-only.md)
4. [Plan 4: Docs and Acceptance](/home/valor/settingZsh/docs/superpowers/plans/2026-04-06-settingzsh-plan-4-docs-and-acceptance.md)

## 切分原則

- 每份 plan 都要在結束時維持 branch 可運作、可驗證。
- 不跨 plan 偷帶未完成前提。
- 先收斂資料模型與 `chezmoi` 消費端，再移除 Python baseline writers，最後才收縮 CLI 與同步文件。

## Spec Coverage

- Spec §5–§8（單核心模型、元件責任、設定模型、平台抽象）→ Plan 1 + Plan 2
- Spec §9–§10（使用者流程、腳本與執行邊界）→ Plan 1 + Plan 3
- Spec §11（測試策略）→ Plan 1 + Plan 2 + Plan 3 + Plan 4
- Spec §12–§14（遷移策略、風險、驗收標準）→ Plan 3 + Plan 4

## 執行守則

- 每完成一份 plan 就跑該 plan 列出的 verification commands。
- 每份 plan 單獨 commit。
- 若任何一步讓 `fresh install` smoke 壞掉，先修回綠再進下一份 plan。
