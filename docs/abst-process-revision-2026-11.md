---
type: Research
title: ABST 流程修订方案：三实践全链路体检（2026-11）
description: 基于 bko 两轮与 HEHE 第三轮实践痕迹、engine/skill/docs 三层代码审计、51 条声明规模性能实测的全面体检；产出 12 项发现（4 批次修订）与文件级实施清单。本文是修订实施的依据文档。
phase: current
status: draft
generated: { by: agent:claude, at: 2026-11-17 }
tags: [abst, testing, process]
---
# ABST 流程修订方案：三实践全链路体检（2026-11）

> 修订范围（已确认）：全链路对齐修订——engine（bin/abst）→ skill（SKILL.md）→ docs（design / field report）→ tests。方法论本体（SEV 元模型、状态机、背书咽喉）经三轮实践验证有效，**本轮不动语义，只修流程**。

## 一、体检方法与输入

- 三层代码审计：`bin/abst`（671 行，逐行）vs `docs/abst-design.md`（345 行）承诺逐条比对；SKILL.md 规程 vs engine 实际命令比对。
- HEHE 第三轮实践痕迹反推：60 条声明的提交历史（e7a0ba3 → 70d6ac1 共 19 个操作提交）与 34009e8"文件混乱"修复删除的 2618 行运行时产物。
- 性能实测：临时仓库构造 51 条声明（2 mission + 5 goal + 44 contract）+ 88 份证据（unit 88 + e2e 44），实测 `verify` 11.2s / `report` 4.4s / `gate --all` 3.2s。

## 二、体检发现（按严重度）

### P0 — 流程正确性 / 防复发

**F1 运行时产物误入仓库：三层缺防 + 残留未清**
- 现象：34009e8 从本仓库删除 2618 行目标仓库运行时产物（registry.json 2184 行、.abst-state.json、abst-report.json、19 个卷宗）；修复后根目录仍残留 `volumes/`（init 模板 3 文件）与空 `evidence-results.json`，且**无 .gitignore 兜底**。
- 根因链：① engine `init` 无防呆——`--root` 缺省 cwd，任何目录静默生成；② SKILL.md 无"必须在目标仓库执行"的防呆铁律；③ 本仓库无 .gitignore。HEHE 实践时 cwd 在本仓库即触发。
- 修订（批次 A）：engine init 防呆（目标已有 `abst/registry.json` 即拒绝，需显式 `--force`）；SKILL.md 铁律补"执行位置防呆"；本仓库加 .gitignore（`abst/`、`*.abst-state` 等运行时模式）；删除根目录残留。

**F2 volumes/ 目录语义冲突**
- 现象：`init` 在 `volumes/` 生成意图四册之三（mission/features/statements.md，§12.2），HEHE 的 e2e 证据卷宗（`resultsFile: abst/volumes/*.json`，19 个）也放同目录——"人读意图资产"与"机器回读证据"混居。
- 修订（批次 A）：init 增发生 `abst/evidence/` 目录；文档与 skill 引导 e2e 卷宗放 `evidence/`；`volumes/` 回归四册专属语义。resultsFile 本是自由路径，存量 HEHE 卷宗不受影响。

### P1 — 流程摩擦（HEHE 三轮实践主痛点）

**F3 endorse/accept 无批量模式**
- 证据：P5 一次性 endorse 10 条（e7a0ba3）；四轮审查修复复证（ca0e0d6/f26d002/f34d687/70d6ac1）每轮重新 accept 多条 human 声明。60 条 × 5 阶段 × 多轮 = **数百次逐条命令**。
- 修订（批次 B）：`endorse --ids a,b,c --by 人` 与 `accept --ids a,b,c --by 人`；执行前输出逐条清单（id + text）供人过目。**批量只是执行效率，不改变"逐条审查是人工职责"的语义**（§12.1"批量通过等于未审查"防的是签名人不看清单，不是打字次数）。

**F4 human 逐次验收缺"按 Δ 重签"仪式**
- 现象：impl 任何触碰 → 命中 human 声明验收签署全部失效 → 逐条重新 accept。审查修复轮轮触发。
- 修订（批次 B）：`accept --files <变更文件>` —— 列出本次 Δ 命中的待签 human 声明清单一屏确认、一次签署。逐次验收语义（§4.3）不变。

**F5 e2e 证据 resultsFile 机器契约未文档化**
- 现象：engine 只认 resultsFile 顶层 `.pass == true/false`（`eval_evidence`）；HEHE 卷宗自发演化出 `{"pass", "at", "note"}` 格式且 note 承载复证叙述（p2-010 卷宗 note 达数百字）——好实践，但契约只在 engine 代码里，AI 每次需逆向发现。
- 修订（批次 B）：design §4.2 与 SKILL.md 取证段明示契约：`.pass`（布尔，必填）+ `at`/`note`（可选，note 为复证叙述规范位）。

### P1 — 性能

**F6 engine O(n²) 求值 + 逐条 jq 重写**
- 实测：51 条/88 证据 → verify 11.2s、report 4.4s、gate --all 3.2s；一次复证循环（verify+report+gate）engine 纯耗时 ~19s。
- 根因：`ev()` 递归经命令替换无缓存；`calc_metrics` 切片循环对每声明反复求值；`cmd_verify` 写回每条声明一次 jq 全文件重写（51 次）+ ACCEPT_CLEAR 再循环。
- 修订（批次 C）：① verify 写回合并为单次 jq（reduce/`--args` 批量）；② ev 结果进程内缓存（关联数组备忘录，bash 3.2 兼容写法）；③ 切片统计复用单次求值。预期 ≥5×。

### P2 — 设计-实现对齐与文档治理

**F7 设计承诺未实现且无状态标注**：证据强度/变异度量（§4.2、§五③）、门禁拦截率（§七）、manifest 脚手架（§五③）engine 均未实现，design 不标注哪些已落地——读者无法分辨体系现状。修订（批次 D）：design 增"实现状态对照表"（✅ engine 0.x / ⏳ 规划 / 🔧 AI 工序）。

**F8 孤儿检测表述不一致**：design §4.4 写"feature/goal 声明是孤儿"，engine 只检 goal（feature 非声明级别，表述本身含糊）。修订（批次 D）：design 修正为 goal 声明（feature 维度经 goal 间接保证）。

**F9 HEHE 第三轮实践复盘缺位**：field report 只有 bko 两轮；批量摩擦、卷宗演化、文件混乱三大教训未沉淀。修订（批次 D）：新增 `docs/abst-field-report-hehe.md`。

**F10 design 自设拆分触发条件临界**："手册超过设计本体 / 第二个实践消费者出现 / 全文超 400 行"——现状 345 行 + HEHE 已是第二消费者，两条已满足/临界。修订（批次 D）：本轮明确记录"暂不拆分"决定及理由（或启动拆分，见决策项）。

**F11 smoke 覆盖缺口**：check 拦截项（refines 悬空/成环、waiver 三元组缺失、impl-refs 空白、id 重复）、gate --all、孤儿检测、e2e 回读、域登记率/积压输出均无用例。修订（批次 D）：smoke 补齐 + 批量命令/防呆用例。

## 三、实施清单（批次 → 文件）

| 批次 | 发现 | 改动 |
| --- | --- | --- |
| A 防复发 | F1 F2 | `bin/abst`（init 防呆 + evidence/ 目录）；`skill/SKILL.md`（执行位置铁律）；`.gitignore`（新增）；删根目录残留 `volumes/`、`evidence-results.json` |
| B 摩擦 | F3 F4 F5 | `bin/abst`（--ids 批量 + accept --files）；`skill/SKILL.md`（批量工作流 + resultsFile 契约）；`docs/abst-design.md`（§4.2 契约一句） |
| C 性能 | F6 | `bin/abst`（写回合并 + ev 缓存 + 切片复用）；`tests/smoke.sh`（性能基准冒烟，防回归） |
| D 对齐 | F7 F8 F9 F10 F11 | `docs/abst-design.md`（状态对照表 + 孤儿表述 + 拆分决策记录）；`docs/abst-field-report-hehe.md`（新增）；`tests/smoke.sh`（补用例） |

每批约束：engine 改动同步 `skill/scripts/abst` 分发副本（R9 校验字节一致）；`tests/smoke.sh` 全绿为批次出口条件；版本号递增（0.1.1 → 0.2.0，批量+防呆属特性）。

## 四、本轮不做（YAGNI）

- **不实现**变异测试/证据强度度量——bash engine 不现实，design 标注"规划中"即可；
- **不实现** manifest 脚手架——属目标仓库技术栈工具（zod/OpenAPI 解析），保留在 skill 工具倾向指引；
- **不重写** engine 语言——bash ≥3.2 兼容是明确决策；
- **不动**状态机/背书咽喉/Gate 白名单语义——三轮实践验证有效。

## 五、决策记录（2026-11-17 用户裁定）

1. **实施范围**：全批次 A-D 一次落地（engine 0.1.1 → 0.2.0）。
2. **F10 拆分**：用户裁定**本轮拆三篇**（推翻本文原"暂不拆"建议）——已执行：abst-philosophy.md / abst-system.md / abst-handbook.md + 总索引 abst-design.md（含实现状态对照表与拆分决策记录）。
3. **F9 复盘素材**：HEHE 仓库不在本机可达路径，已基于提交历史与产物痕迹完成骨架版（docs/abst-field-report-hehe.md），仓库可达后充实。

## 六、实施结果（engine 0.2.0）

| 批次 | 结果 |
| --- | --- |
| A | init 防呆（既有 registry 拒绝 + `--force` 补缺失）；`abst/evidence/` 卷宗目录与契约 README；SKILL 铁律 5（执行位置防呆）；.gitignore；根目录残留清除 |
| B | `endorse/accept --ids` 批量（清单先行、任一不存在整批拒绝、幂等）；`accept --files` 按 Δ 列待签清单一批重签；e2e 卷宗契约文档化（design §4.2 + SKILL + evidence/README） |
| C | load_state 单次 jq TSV 导出（US 0x1f 分隔防空字段塌陷）；ev 无 fork + 进程内缓存（S_VERDICT 修改处清缓存）；预计算背书 hash/文件 hash/基线表；verify 写回合并单次 jq；实测 51 条/88 证据 verify 11.2s→2.4s、report 4.4s→0.8s、gate 3.2s→0.9s（bench.sh 120 条线性伸缩 5.7s/2.1s/2.3s） |
| D | 三篇拆分 + 总索引（实现状态对照表）；孤儿表述修正（goal 级 + feature 间接保证）；HEHE 复盘骨架；smoke 从 21 用例扩至 40（批量/防呆/e2e 回读/check 拦截/孤儿/gate --all/度量输出）；README 对齐 |

实施中新发现并同步修复：命令行 `--ids` 与全局声明数组 `IDS` 同名冲突；TSV 空字段被 IFS 空白折叠（改 US 分隔）；ev 两参数误拼为单参数（尾随空格）；最终重算前内存基线未随新 STATE 刷新；probe/e2e 新鲜度秒级竞态（同秒视为新）。全部有 smoke 用例或复现脚本佐证，连续三轮全绿。
