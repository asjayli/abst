---
name: abst
description: ABST（Auto Business Statement Testing）业务声明测试体系的 AI 执行规程——意图声明派生、背书咽喉、探针取证、判定刷新、Gate 放行。Use when working with ABST registries (abst/registry.json), deriving business statements from specs, running abst init/endorse/verify/gate/doctor commands, or when user mentions ABST, 意图声明, 业务声明测试, AI Auto Acceptance, C(G), 背书, DRAFT/STALE 声明状态.
---

# ABST — AI 执行规程

ABST 以意图声明为唯一被测对象，目的是 AI Auto Acceptance。**你是执行者，不是判定者**：判定权在确定性 engine（`scripts/abst`，bash 实现），你的职责是派生、取证、评审——并严格遵守背书咽喉。

方法论本体：<https://github.com/asjayli/abst/blob/main/docs/abst-design.md>（§编号在下文中均指该文档）。

## 铁律（违反即体系失效）

1. **背书是咽喉，不是待办**：声明未经人工 `endorse`，不得产生正式证据、不得计入覆盖率、不得放行。可以先准备 `status=draft` 的草案证据帮人评审，但转正的唯一前提是背书完成。永远不要把"请人工签署"排到覆盖率跑完之后汇报。
2. **派生锚定规格源**：从 openspec/需求文档派生声明（`derived-from: spec`）；只有代码时允许反推起步，但必须标 `derived-from: code` 并在评审时最高优先级质疑——代码→声明→验证代码的链条永远自洽，是盖章机。
3. **判定只信 engine**：覆盖率、状态、放行结论一律以 `abst report` / `abst gate` 输出为准，不要自己数 registry 下结论（自报 ≠ 事实）。
4. **VIOLATED 三叉定位**（§九）：先判实现错/声明错/证据错再动手。声明错走升版流程（改 text + version +1），升版后声明自动回 DRAFT 待重新背书——绝不改码迁就声明，也绝不悄悄改声明迁就码。

## 命令（engine）

```bash
<skill目录>/scripts/abst <cmd> [--root 目标仓库]
```

| 命令 | 何时用 |
| --- | --- |
| `init` | 目标仓库首次落地：生成 `abst/`（registry、glossary、意图四册模板） |
| `endorse <id> --by 人` | 人工背书落锤（DRAFT → UNPROVEN）。你只准备材料，由人执行或人明确授权后执行 |
| `accept <id> --by 人` | `signatory=human` 声明的逐次验收签署 |
| `check` / `doctor` | 完整性 + 健康度体检；CI 必跑，退出码非零即体系有债 |
| `verify` | 证据执行后刷新判定（含回读与 STALE 传播） |
| `report` | C(G)——永远与批准率、积压成对出现，禁止单独引用 C(G) |
| `gate --files a,b` | 交付放行判定（CI 在 MR/merge 前跑） |

## 标准工作流

**落地（存量工程）**：
1. `init` → 读规格与代码，`abst doctor` 确认骨架；
2. 派生声明草案写入 `registry.json`：每条含 §4.1 全字段（text 用 FDD 句式 + Glossary 术语、boundary/elasticity 非空、refines 挂到 goal/mission、impl-refs 列实现文件）；
3. **停下来交人背书**：输出逐条审查清单（声明文本 + 你的派生依据 + 存疑点），goal/mission 级附异构评审意见（扮演魔鬼代言人质疑"应然合理吗"）；
4. 人 `endorse` 后才开始取证。

**取证（③④）**：端点有机器可读 schema（zod/OpenAPI）先生成 manifest 再"填空式"写探针；探针结果写入 `evidence-results.json`（`{"<evidence-id>": {"status": "pass|fail"}}`）后跑 `verify`。委托证据按形态登记：static（file+anchor）/ unit（file+marker）/ e2e（resultsFile）——engine 负责回读。

**交付**：`gate --files <变更文件>`，通过才可合并；未过按输出清单消账。

## 工具倾向（降 token、防幻觉）

确定性的读取与分析**优先**走工具，你只做语义判断（设计文档 §十四）：

- 派生：有 openspec 就读规格 diff；没有则读需求文档/代码，但结论标注 `derived-from` 与出处；
- 影响面与 `impl-refs` 候选：有 codegraph/LSP 就用工具生成；没有则翻代码定位，逐条给出文件+行号；
- 证据锚点定位：优先 ast-grep/semgrep；
- 评审：有 open-code-review 类工具先跑工具，异构模型复核语义，分歧交人；
- 静态扫描（semgrep/CodeQL）的产出可直接登记为 contract 级证据；没有就不登记此类证据，不留空口断言。

**这是倾向不是前提**：本地没有对应工具时对应环节退化为手动执行，体系照常成立——但一切进入注册表与证据链的事实性内容都必须带可复核出处（文件 + 行号），你的无出处转述不算事实来源。

## registry 速查

- 状态机（§4.3）：`DRAFT →(endorse)→ UNPROVEN →(证据通过)→ PROVEN`；失败 → `VIOLATED`；impl-refs 变更 → `STALE`；语义升版 → 回 `DRAFT`；豁免 → `WAIVED`（到期自动回落）；`DELEGATED` 只是手工登记的过渡态——engine 不存储它，`verify` 的委托回读（static/unit/e2e 三形态）会把它解算为 PROVEN/VIOLATED，Gate 对未解算的 DELEGATED 一律转人工；
- 证据 `status`：`draft`（评审材料，不计判定）/ `official`（须声明已背书，否则 `check` 报错）；
- goal 判定 = 子声明合取（§4.4）：子声明任一 VIOLATED，goal 拉红——改 goal 前先修子声明。
