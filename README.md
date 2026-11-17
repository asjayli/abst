# ABST — Auto Business Statement Testing

自动（**A**uto）地对业务（**B**usiness）的意图声明（**S**tatement）进行测试（**T**esting）。

ABST 是一个业务侧测试体系：以**意图声明**为唯一被测对象、以 **AI Auto Acceptance（AI 自动验收）**为目的。它脱胎于 ATDD/BDD/SDD（声明的三个抽象级别）、FDD（组织单元 Feature）、DDD（统一语言词汇表），但不做分层堆叠——**一个被测对象，一条生命周期，一个判定机，一个放行函数**。它是对已建成的 UT/IT/E2E 技术层测试的补全（validation），不是替代（verification）。

## 仓库内容

```
├── docs/abst-design.md            # 方法论总索引：三篇导航 + §编号归属 + 实现状态对照表
├── docs/abst-philosophy.md        # 上篇·思想总纲（§一~§三：为什么）
├── docs/abst-system.md            # 中篇·体系设计（§四~§十一：SEV 元模型/生命周期/Gate/度量）
├── docs/abst-handbook.md          # 下篇·工程手册（§十二~§十四：意图具象化/落地路径/工具链）
├── docs/abst-field-report-bko.md  # 第 1-2 轮实践检验（bko：48 声明、6 个生产 bug）
├── docs/abst-field-report-hehe.md # 第 3 轮实践检验（HEHE：60 声明、P1-P5 五阶段）
├── docs/abst-process-revision-2026-11.md # 三实践全链路体检与流程修订方案（本次 0.2.0 的依据）
├── bin/abst                       # ABST engine：确定性判定机（bash ≥ 3.2，依赖 jq + coreutils）
├── skill/SKILL.md                 # ABST agent skill：AI 执行者的操作规程
├── skill/scripts/abst             # engine 的分发副本（bin/abst 是唯一源，tests/smoke.sh 校验一致性）
├── tests/smoke.sh                 # 冒烟回归：全生命周期 + Gate 假绿 + 批量/防呆/check 拦截用例
├── tests/bench.sh                 # 性能基准：N 条声明计时 verify/report/gate（只计时不断言）
└── install.sh                     # 安装/卸载（engine symlink + skill 安装 + 依赖检查 + 自检）
```

## 两层结构

ABST 的执行者是 AI，但**判定权在确定性工具**（设计文档 §二：确定性与概率性分离）：

- **Engine**（`bin/abst`）：注册表完整性、背书 hash 校验、状态机迁移、回读、C(G)、Gate——每次必跑，不靠 AI 自觉；
- **Skill**（`skill/SKILL.md`）：把背书咽喉纪律、派生方法（读规格而非读代码）、异构评审工序、三叉定位诊断编码为 AI 的强制流程。

## 安装

```bash
./install.sh            # engine → ~/.local/bin/abst，skill → ~/.agents/skills/abst
./install.sh uninstall  # 卸载
```

## 快速开始

```bash
abst init   # 在目标仓库生成 abst/ 资产（独立顶层目录，不寄居于 e2e/）
```

然后向 `abst/registry.json` 的 `statements` 数组写入第一条声明（通常由 AI 从规格派生）：

```json
{
  "id": "QUOTA-001",
  "text": "单任务并发上限等于 8",
  "level": "contract",
  "feature": "quota",
  "signatory": "auto",
  "executable": true,
  "weight": 2,
  "version": 1,
  "derived-from": "spec",
  "boundary": "仅单任务作用域",
  "elasticity": "8 可配置",
  "created-at": "2026-08-11T00:00:00.000Z",
  "impl-refs": ["src/quota.ts"],
  "evidence": [
    { "id": "p-quota-001", "form": "probe", "status": "official" },
    { "id": "s-quota-001", "form": "static", "status": "official", "file": "src/quota.ts", "anchor": "quota-max-const" }
  ]
}
```

```bash
abst endorse QUOTA-001 --by zhangsan   # 人工背书——咽喉，先于一切取证
echo '{"p-quota-001": {"status": "pass"}}' > abst/evidence-results.json
abst verify                            # 刷新判定（含委托回读与 STALE 传播）
abst report                            # C(G) 强制与批准率、积压成对输出
abst gate --files src/quota.ts         # 交付放行判定
abst doctor                            # 体检：完整性 + 健康度
```

约束：`impl-refs`、`--files` 的路径不含空白字符（engine 按空白分词）；路径相对仓库根、不带 `./` 前缀（engine 会规范化，但建议保持一致）。

## 命令一览

| 命令 | 对应生命周期 | 说明 |
| --- | --- | --- |
| `init` | §十三 | 脚手架：registry / glossary / 意图四册模板 / evidence/ 卷宗目录；目标已有 registry.json 时拒绝（`--force` 仅补缺失文件） |
| `endorse <id\|--ids a,b,c> --by <人>` | ②背书 | 写入 endorsement 记录（DRAFT → UNPROVEN 的唯一通道）；批量先输出逐条清单，任一 id 不存在整批拒绝 |
| `accept <id\|--ids a,b,c\|--files Δ> --by <人>` | ⑥签署 | `signatory=human` 声明的逐次验收签署（impl 变更即失效）；`--files` 按本次变更列待签清单一批重签 |
| `check` | — | 完整性检查（DRAFT 持正式证据、豁免缺失/超期、refines 悬空/成环、孤儿、证据形态非法等）；id/impl-refs 非法字符 fail-fast |
| `verify` | ④⑤ | 消费证据结果 → 状态机迁移；委托证据回读；impl-refs 变更置 STALE |
| `report` | §七 | C(G)（仅已背书且未豁免分母）+ 批准率 + 积压，强制成对输出 |
| `gate --files …` | §六 | 放行函数：白名单制，空 S(Δ)/DRAFT/STALE/DELEGATED/孤儿/未签署一律转人工 |
| `doctor` | §七 | 健康度总览，有完整性错误时退出码非零 |

engine 当前未覆盖设计文档中的两个度量项（证据强度分布、门禁拦截率）——它们依赖变异测试与 CI 统计接入，属后续迭代；完整对齐快照见 [docs/abst-design.md](docs/abst-design.md) 实现状态对照表。

## 测试

```bash
tests/smoke.sh   # 全生命周期冒烟 + Gate 假绿回归 + 批量签署/init 防呆/check 拦截/e2e 回读用例
tests/bench.sh   # 性能基准：51 条声明计时（2026-11 优化后 verify≈2.4s / report≈0.8s / gate≈0.9s）
```

## License

[MIT](LICENSE) © asjayli
