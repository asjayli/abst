---
type: Architecture
title: ABST 自动化业务声明测试体系设计（总索引）
description: ABST（Auto Business Statement Testing）方法论本体总索引——一句话定位、三篇结构导航（思想总纲/体系设计/工程手册）、§编号归属表、实现状态对照表、文档拆分决策记录。方法论正文自 2026-11 起拆为三篇独立文档。
phase: current
status: draft
generated: { by: agent:kimi-code/kimi, at: 2026-08-10 }
tags: [atdd, bdd, sdd, tdd, testing]
---
# ABST 自动化业务声明测试体系设计（总索引）

**ABST = Auto Business Statement Testing（自动化业务声明测试）**——自动（Auto）地对业务（Business）的意图声明（Statement）进行测试（Testing）。以**意图声明**为唯一被测对象、以 **AI Auto Acceptance（AI 自动验收）**为目的：**Statement 是对象，Testing 是手段，Acceptance 是目的，AI 是执行者**。一个被测对象、一条生命周期、一个判定机、一个放行函数。

## 三篇结构（2026-11 拆分）

| 篇 | 文档 | 回答 | 章节 |
| --- | --- | --- | --- |
| 上篇 · 思想总纲 | [abst-philosophy.md](abst-philosophy.md) | 为什么 | §一 第一性原理 · §二 AI 执行者前提 · §三 已知边界 |
| 中篇 · 体系设计 | [abst-system.md](abst-system.md) | 是什么 | §四 SEV 元模型 · §五 生命周期 · §六 Gate · §七 度量 · §八 成熟度 · §九 失败语义 · §十 技术层接口 · §十一 方法论溯源 |
| 下篇 · 工程手册 | [abst-handbook.md](abst-handbook.md) | 怎么做 | §十二 意图具象化 · §十三 落地路径 · §十四 工具链倾向 |

**§编号跨篇连续沿用**：历史引用"设计文档 §X"按下表归属解析——§一~§三 → 思想总纲；§四~§十一 → 体系设计；§十二~§十四 → 工程手册。

**拆分决策记录**（原"文档结构"节自设的拆分触发条件：手册超过设计本体 / 第二个实践消费者出现 / 全文超 400 行 / 三篇需不同 status 分轨）：2026-11 三实践（bko 两轮 + HEHE 一轮）后，"第二消费者出现"已满足、345 行临近 400 行阈值，随流程修订（[abst-process-revision-2026-11.md](abst-process-revision-2026-11.md)）一并完成拆分；三篇 status 暂不分轨，仍统一 draft。

## 实现状态对照表

设计承诺与 engine（本仓库 `bin/abst`）实现的对齐快照——读者据此分辨"体系现状"与"规划方向"：

| 设计承诺 | 位置 | 状态 |
| --- | --- | --- |
| 注册表 / 状态机（DRAFT→UNPROVEN→PROVEN / VIOLATED / STALE / WAIVED） | §4.3 | ✅ engine 0.2.0 |
| goal 判定合取（子声明失败拉红 goal） | §4.4 | ✅ engine 0.2.0 |
| 入库背书（text+version hash 绑定、升版失效）、批量 endorse | §4.1 §五② | ✅ engine 0.2.0（--ids 批量） |
| 验收签署（signatory=human 逐次、impl 变更失效）、按 Δ 批量重签 | §4.3 §五⑥ | ✅ engine 0.2.0（accept --files） |
| Gate 白名单制 / S(Δ) 闭包 / 孤儿拦截 | §六 | ✅ engine 0.2.0 |
| 度量：C(G)+批准率+背书积压+豁免+新鲜度+域登记率 | §七 | ✅ engine 0.2.0（C(G) 强制成对输出） |
| 委托证据回读三形态（static 锚点 / unit 标记 / e2e resultsFile） | §五④ | ✅ engine 0.2.0 |
| e2e 卷宗机器契约（`.pass` 布尔必填；`at`/`note` 推荐） | §4.2 | ✅ engine 0.2.0 + evidence/ 目录 |
| init 防呆（既有资产拒绝 + evidence/ 卷宗目录） | §十 | ✅ engine 0.2.0 |
| 证据强度（变异测试/异构评审度量、"强度不达标=无证据"） | §4.2 §五③ | ⏳ 规划中（异构评审已规程化为 AI 工序，见 skill） |
| 门禁拦截率指标 | §七 | ⏳ 规划中 |
| 探针 manifest 脚手架（schema→manifest→填空） | §五③ | ⏳ 规划中（skill 工具倾向保留指引；属目标仓库技术栈工具） |
| 异构 AI 评审（魔鬼代言人、T→T'→OT） | §五②③ | 🔧 AI 工序（SKILL.md 规程化，engine 不判定） |
| Gate 消费技术层全绿信号 | §六 | ✅ 接口留白（engine 不消费，CI 合取） |

## 相关

- [ABST 实践检验报告：bko 试点](abst-field-report-bko.md)（两轮）
- [ABST 实践检验报告：HEHE 试点](abst-field-report-hehe.md)（第三轮）
- [ABST 流程修订方案：三实践全链路体检](abst-process-revision-2026-11.md)
