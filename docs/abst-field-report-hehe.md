---
type: Research
title: ABST实践检验报告：HEHE试点（第三轮）
description: ABST 第三轮实践（HEHE 平台，2026-08~09）——60 条声明按 P1-P5 五阶段全量推进、70 份异构证据（unit38+static14+e2e18）、四轮审查修复复证；暴露批量签署摩擦、运行时产物误入方法论仓库、卷宗目录语义混用三个体系级流程问题，驱动 2026-11 流程修订（engine 0.2.0）。骨架版：基于提交历史与产物痕迹撰写，HEHE 仓库内细节待补充。
phase: current
status: draft
generated: { by: agent:claude, at: 2026-11-17 }
tags: [abst, testing]
---
# ABST 实践检验报告：HEHE 试点（第三轮，2026-08~09）

> 本文是 [ABST 体系设计](abst-design.md)的第三轮实践复盘（前两轮见 [bko 报告](abst-field-report-bko.md)），属经验性记录；方法论本体以设计文档三篇为准。**诚实条款：本文为骨架版**——依据 ABST 仓库内的提交历史（e7a0ba3…70d6ac1 共 19 个操作提交）与运行时产物痕迹撰写，HEHE 业务仓库不在本机可达路径，声明文本全集、审查分歧明细等待仓库可达后充实。

## 一、背景与总量

- **对象**：HEHE 平台（内部系统；含 talk/message、工作项、agent 记忆等域）。
- **推进方式**：按 P1-P5 五个阶段全量登记与验收（区别于 bko 的单域试点），最终 **60 条声明**、C(G) 达到 100%（60/60）。
- **证据形态分布**（registry 2184 行，误入产物中实测）：unit 38 + static 14 + e2e 18 = **70 份，零 probe**——与 bko 轮（探针为主）形态相反：委托既有测试资产成为主力，探针仅在无既有覆盖时手写。判重原则（§十）在真实存量工程中的兑现率远超预期。
- **e2e 卷宗格式自发演化**：`{"pass": bool, "at": ISO8601, "note": <复证叙述>}`——note 承载完整的"做了什么、改了什么、证据链如何闭合"叙述（p2-010 卷宗 note 达数百字，含 DDL 缺陷定位与修复路径）。这一实践后被吸收为正式机器契约（§4.2，engine 0.2.0 的 evidence/README）。

## 二、被实践证实为真的

1. **分阶段全量推进可行**：P1→P5 每阶段"注册（全 DRAFT）→ 背书 → 取证 → 验收签署 → verify/report 收口"的节奏跑通；goal/mission 层验收（G1-G5 + MISSION PROVEN）完成。
2. **STALE 自洁与逐次验收在审查循环中起效**：四轮审查修复（P0/P1/P2/H-4/M-C5）每轮都触发"实现变更 → human 声明验收失效 → 重新签署 + 复证"链条，机制按设计运转。
3. **e2e 取证真实揪出实现缺陷**：P2-010 复证检出 P1 talk DDL 两处缺陷（id VARCHAR(32)→64 截断、ts 毫秒精度丢失致验签失败），及 thread_root_id/reply_to_id 同款列宽问题——业务声明驱动的取证继续命中技术层盲区。
4. **委托回读守住诚实性**：static/unit/e2e 三形态回读使"我说它存在"降为可校验事实（bko 轮改进建议 #3 的落地验证）。

## 三、实践中真实撞到的（驱动 2026-11 流程修订）

1. **批量签署摩擦（最重）**：60 条 × 五阶段 × 多轮复证 = 数百次逐条 `endorse`/`accept`；四轮审查修复每轮都要重新逐条签署命中的 human 声明。→ 修订：`--ids` 批量 + `accept --files`（按 Δ 列待签清单一批签署），engine 0.2.0。
2. **运行时产物误入方法论仓库**：HEHE 实践期间在 ABST 仓库根误执行 `init`（及后续 verify），registry/.abst-state/abst-report/19 个卷宗共 **2618 行误提交**（34009e8 修复删除，残留 volumes/ 模板与空 evidence-results.json 至 2026-11）。三层缺防：engine init 无防呆、skill 规程无执行位置铁律、仓库无 .gitignore。→ 修订：init 既有资产拒绝（--force 补齐缺失）、SKILL 铁律 5（执行位置防呆）、.gitignore 兜底。
3. **卷宗目录语义混用**：init 生成的 `volumes/`（意图四册，人读）与 HEHE e2e 证据卷宗（机器回读）同目录混放，是"文件混乱"的组成部分。→ 修订：`abst/evidence/` 独立卷宗目录 + 契约文档化（`.pass` 必填、note 规范位）。
4. **engine 性能在 60 条规模可感**：一次复证循环（verify+report+gate）纯 engine 耗时约 19s（51 条/88 证据实测外推），叠加数百次逐条命令放大等待。→ 修订：load_state TSV 单次导出、ev 无 fork+缓存、verify 单次 jq 写回——实测 verify 11.2s→2.7s、report 4.4s→0.9s、gate 3.2s→1.0s。

## 四、修订映射

全部发现与修订项见 [abst-process-revision-2026-11.md](abst-process-revision-2026-11.md)（F1-F11），已按批次 A-D 落地为 engine 0.2.0 + SKILL.md + 设计文档三篇拆分。

## 五、一句话总结

第三轮实践把 ABST 从"单域试点可行"推进到"分阶段全量可行"，委托既有测试资产的判重兑现让取证成本大幅低于 bko 轮；同时三轮累积的操作摩擦（批量、防误、目录语义、性能）集中显形——它们不属于方法论语义层，全部收敛为工程层的流程修订，状态机与背书咽喉未被触碰。

## 相关
- [ABST 体系设计（总索引）](abst-design.md)
- [ABST 实践检验报告：bko 试点](abst-field-report-bko.md)
- [ABST 流程修订方案：三实践全链路体检](abst-process-revision-2026-11.md)
