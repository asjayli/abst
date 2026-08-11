#!/usr/bin/env bash
# ABST 冒烟回归测试：全生命周期 + Gate 假绿回归用例。
# 用法：tests/smoke.sh [engine 路径]（默认 ../bin/abst）。兼容 bash >= 3.2。
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="${1:-$HERE/../bin/abst}"
[[ -x "$ENGINE" ]] || { echo "engine 不可执行：$ENGINE" >&2; exit 2; }

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
cd "$T"
FAILED=0

ok() { # $1=描述 $2=期望退出码 $3...=命令
  local desc="$1" want="$2"; shift 2
  local got=0
  "$@" >/dev/null 2>&1 || got=$?
  if [[ "$got" == "$want" ]]; then echo "✓ $desc"; else echo "✗ $desc（期望退出码 $want，实得 $got）"; FAILED=1; fi
}
ok_out() { # $1=描述 $2=期望包含的子串 $3...=命令
  local desc="$1" want="$2"; shift 2
  local out
  out="$("$@" 2>&1 || true)"
  if [[ "$out" == *"$want"* ]]; then echo "✓ $desc"; else echo "✗ $desc（输出缺少：$want）"; FAILED=1; fi
}

# ---------- 夹具 ----------
mkdir src
echo 'export const CORE = 1;' > src/core.ts
echo 'export const GOAL = 1; // goal-anchor' > src/goal.ts
echo 'export const QUOTA_MAX = 8; // anchor: quota-max-const' > src/quota.ts
echo 'export const DELEG = 1; // deleg-anchor' > src/deleg.ts
"$ENGINE" init >/dev/null
cat > abst/registry.json <<'EOF'
{
  "version": 1,
  "domains": ["quota", "core"],
  "statements": [
    {"id": "MISSION-001", "text": "产品服务于个人知识资产的长期复利", "level": "mission", "feature": "core", "signatory": "human", "executable": false, "weight": 3, "version": 1, "derived-from": "spec", "boundary": "宗旨", "elasticity": "无", "created-at": "2026-08-10T00:00:00.000Z", "impl-refs": ["src/core.ts"]},
    {"id": "GOAL-QUOTA", "text": "配额域做到超额请求全部被拒绝即完成", "level": "goal", "feature": "quota", "signatory": "auto", "executable": true, "weight": 3, "version": 1, "derived-from": "spec", "boundary": "仅 API 层", "elasticity": "阈值可配置", "refines": ["MISSION-001"], "created-at": "2026-08-10T00:00:00.000Z", "impl-refs": ["src/goal.ts"], "evidence": [{"id": "s-goal", "form": "static", "status": "official", "file": "src/goal.ts", "anchor": "goal-anchor"}]},
    {"id": "QUOTA-001", "text": "单任务并发上限等于 8", "level": "contract", "feature": "quota", "signatory": "auto", "executable": true, "weight": 2, "version": 1, "derived-from": "spec", "boundary": "仅单任务", "elasticity": "8 可配置", "refines": ["GOAL-QUOTA"], "created-at": "2026-08-10T00:00:00.000Z", "impl-refs": ["src/quota.ts"], "evidence": [{"id": "p1", "form": "probe", "status": "official"}, {"id": "s1", "form": "static", "status": "official", "file": "src/quota.ts", "anchor": "quota-max-const"}]},
    {"id": "DELEG-001", "text": "委托既有测试的声明", "level": "behavior", "feature": "core", "signatory": "auto", "executable": true, "weight": 1, "version": 1, "derived-from": "spec", "boundary": "无", "elasticity": "无", "created-at": "2026-08-10T00:00:00.000Z", "impl-refs": ["src/deleg.ts"], "evidence": [{"id": "d1", "form": "static", "status": "official", "file": "src/deleg.ts", "anchor": "deleg-anchor"}]}
  ]
}
EOF

# ---------- 生命周期 ----------
for id in MISSION-001 GOAL-QUOTA QUOTA-001 DELEG-001; do "$ENGINE" endorse "$id" --by tester >/dev/null; done
"$ENGINE" accept MISSION-001 --by tester >/dev/null
ok "check：干净注册表通过" 0 "$ENGINE" check
echo '{"p1": {"status": "pass"}}' > abst/evidence-results.json
sleep 1
"$ENGINE" verify >/dev/null
ok "gate：全绿放行" 0 "$ENGINE" gate --files src/quota.ts
ok_out "report：C(G) 与批准率成对输出" "应然批准率" "$ENGINE" report

# ---------- 回归：Gate 假绿防护 ----------
# R1 空 S(Δ) 默认拒绝（白名单制）
ok "R1：--files 未命中 → 空 S(Δ) 拒绝放行" 1 "$ENGINE" gate --files src/nonexist.ts
# R2 ./ 前缀规范化后可命中
ok "R2：./ 前缀规范化后正常放行" 0 "$ENGINE" gate --files ./src/quota.ts

# R3 DELEGATED fail-closed：手工登记 DELEGATED 判定
jq '(.statements[] | select(.id=="DELEG-001")).verdict = "DELEGATED"' abst/registry.json > /tmp/abst-reg.$$ && mv /tmp/abst-reg.$$ abst/registry.json
ok "R3：DELEGATED 未回读 → 转人工" 1 "$ENGINE" gate --files src/deleg.ts
"$ENGINE" verify >/dev/null  # verify 经委托回读解算为 PROVEN
ok "R3b：verify 回读解算 DELEGATED → 放行" 0 "$ENGINE" gate --files src/deleg.ts

# R4 goal 合取：goal 自带证据通过但子声明失败 → goal 拉红
sleep 1
echo '{"p1": {"status": "fail"}}' > abst/evidence-results.json
"$ENGINE" verify >/dev/null
ok "R4：子声明 VIOLATED → 合取拉红 goal → 转人工" 1 "$ENGINE" gate --files src/quota.ts
ok_out "R4b：report 显示 VIOLATED" "QUOTA-001" "$ENGINE" report
echo '{"p1": {"status": "pass"}}' > abst/evidence-results.json
sleep 1
"$ENGINE" verify >/dev/null
ok "R4c：修复后恢复放行" 0 "$ENGINE" gate --files src/quota.ts

# R5 STALE 持久化：实现变更、证据未复跑 → 拦截；复跑 → 恢复
echo 'export const QUOTA_MAX = 16; // anchor: quota-max-const' > src/quota.ts
sleep 1
"$ENGINE" verify >/dev/null
ok "R5：实现变更未复跑 → STALE 拦截" 1 "$ENGINE" gate --files src/quota.ts
"$ENGINE" verify >/dev/null  # 再 verify 一次（旧结果不得洗白 STALE）
ok "R5b：旧证据结果反复 verify 不得洗白 STALE" 1 "$ENGINE" gate --files src/quota.ts
sleep 1
echo '{"p1": {"status": "pass"}}' > abst/evidence-results.json  # 证据真正复跑
"$ENGINE" verify >/dev/null
ok "R5c：证据复跑后恢复放行" 0 "$ENGINE" gate --files src/quota.ts

# R6 逐次验收：human 声明 impl 变更 → 验收签署失效
echo 'export const CORE = 2;' > src/core.ts
sleep 1
"$ENGINE" verify >/dev/null
ok "R6：human 声明 impl 变更 → 签署失效转人工" 1 "$ENGINE" gate --files src/core.ts
"$ENGINE" accept MISSION-001 --by tester >/dev/null
ok "R6b：重新验收签署后放行" 0 "$ENGINE" gate --files src/core.ts

# R7 语义升版 → 回 DRAFT → 拦截
jq '(.statements[] | select(.id=="QUOTA-001")) |= (. + {text: "单任务并发上限等于 16", version: 2})' abst/registry.json > /tmp/abst-reg.$$ && mv /tmp/abst-reg.$$ abst/registry.json
ok "R7：语义升版 → DRAFT → 转人工" 1 "$ENGINE" gate --files src/quota.ts
ok "R7b：DRAFT 持正式证据 → check 拦截" 1 "$ENGINE" check
"$ENGINE" endorse QUOTA-001 --by tester >/dev/null
sleep 1
echo '{"p1": {"status": "pass"}}' > abst/evidence-results.json  # 新文本需重新取证
"$ENGINE" verify >/dev/null
ok "R7c：重新背书 + 复证后放行" 0 "$ENGINE" gate --files src/quota.ts

# R8 豁免超期 → check 拦截
jq '(.statements += [{"id": "W-001", "text": "体验类", "level": "behavior", "feature": "core", "signatory": "auto", "executable": false, "weight": 1, "version": 1, "derived-from": "code", "boundary": "无", "elasticity": "无", "created-at": "2026-08-10T00:00:00.000Z", "waiver": {"reason": "体感", "expires": "2026-01-01T00:00:00.000Z", "by": "tester"}}])' abst/registry.json > /tmp/abst-reg.$$ && mv /tmp/abst-reg.$$ abst/registry.json
ok "R8：waiver 超期 → doctor 非零" 1 "$ENGINE" doctor

# ---------- 防漂移：engine 双副本一致性 ----------
if [[ -f "$HERE/../skill/scripts/abst" ]]; then
  if cmp -s "$HERE/../bin/abst" "$HERE/../skill/scripts/abst"; then
    echo "✓ R9：bin/abst 与 skill/scripts/abst 字节一致"
  else
    echo "✗ R9：engine 双副本漂移（bin/abst ≠ skill/scripts/abst）"; FAILED=1
  fi
fi

echo
if [[ $FAILED == 0 ]]; then echo "全部通过"; else echo "存在失败用例"; exit 1; fi
