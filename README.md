# ABST — Auto Business Statement Testing

自动（**A**uto）地对业务（**B**usiness）的意图声明（**S**tatement）进行测试（**T**esting）。

ABST 是一个业务侧测试体系：以**意图声明**为唯一被测对象、以 **AI Auto Acceptance（AI 自动验收）**为目的。它脱胎于 ATDD/BDD/SDD（声明的三个抽象级别）、FDD（组织单元 Feature）、DDD（统一语言词汇表），但不做分层堆叠——**一个被测对象，一条生命周期，一个判定机，一个放行函数**。它是对已建成的 UT/IT/E2E 技术层测试的补全（validation），不是替代（verification）。

## 仓库内容

```
├── docs/abst-design.md            # 方法论本体：思想总纲 → 体系设计（SEV 元模型）→ 工程手册
├── docs/abst-field-report-bko.md  # 首轮实践检验报告（48 声明、6 个生产 bug、两轮落地复盘）
├── bin/abst                       # ABST engine：确定性判定机 CLI（bash，依赖 jq + GNU coreutils）
└── skill/SKILL.md                 # ABST agent skill：AI 执行者的操作规程
```

## 两层结构

ABST 的执行者是 AI，但**判定权在确定性工具**（设计文档 §二：确定性与概率性分离）：

- **Engine**（`bin/abst`，bash ≥ 3.2，依赖 jq + coreutils，GNU/BSD 均可）：注册表完整性、背书 hash 校验、状态机迁移、回读、C(G)、Gate——每次必跑，不靠 AI 自觉；
- **Skill**（`skill/SKILL.md`）：把背书咽喉纪律、派生方法（读规格而非读代码）、异构评审工序、三叉定位诊断编码为 AI 的强制流程。

## 快速开始

```bash
# 安装：engine 链接到 ~/.local/bin + skill 安装到 ~/.agents/skills/abst（含依赖检查与自检）
./install.sh          # 卸载：./install.sh uninstall

# 在目标仓库中初始化 ABST 资产（独立顶层目录，不寄居于 e2e/）
abst init

# AI 派生声明草案（DRAFT）后，人工逐条背书——这是咽喉，先于一切取证
abst endorse QUOTA-001 --by zhangsan

# 取证执行后刷新判定（含委托证据回读与 STALE 传播）
abst verify

# 覆盖率报告（C(G) 强制与应然批准率、背书积压成对输出）
abst report

# 交付放行判定
abst gate --files src/server/routers/quota.ts

# 体系体检：完整性错误、积压、STALE、豁免超期、孤儿、域登记率
abst doctor
```

## 命令一览

| 命令 | 对应生命周期 | 说明 |
| --- | --- | --- |
| `init` | §十三 | 脚手架：registry / glossary / 意图四册模板 |
| `endorse <id> --by <人>` | ②背书 | 写入 endorsement 记录（DRAFT → UNPROVEN 的唯一通道） |
| `accept <id> --by <人>` | ⑥签署 | `signatory=human` 声明的逐次验收签署 |
| `check` | — | 完整性检查（DRAFT 持正式证据、豁免缺失/超期、refines 悬空） |
| `verify` | ④⑤ | 消费证据结果 → 状态机迁移；委托证据回读；impl-refs 变更置 STALE |
| `report` | §七 | C(G)（仅已背书且未豁免分母）+ 批准率 + 积压，强制成对输出 |
| `gate --files …` | §六 | 放行函数：白名单制，DRAFT/STALE/孤儿/未签署一律转人工 |
| `doctor` | §七 | 健康度总览，有完整性错误时退出码非零 |

## License

[MIT](LICENSE) © asjayli
