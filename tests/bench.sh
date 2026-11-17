#!/usr/bin/env bash
# ABST engine 性能基准：构造 N 条声明（含 mission/goal/contract 层级 + unit/e2e 证据），
# 计时 verify / report / gate --all。只输出耗时不断言（机器差异大，硬阈值会抖）——
# 用于优化前后的人工对比与回归观察。基准：51 条 + 88 份证据，2026-11 优化前
# verify 11.2s / report 4.4s / gate 3.2s，优化后 2.7s / 0.9s / 1.0s。
# 用法：tests/bench.sh [engine 路径] [声明条数，默认 51]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="${1:-$HERE/../bin/abst}"
N="${2:-51}"
[[ -x "$ENGINE" ]] || { echo "engine 不可执行：$ENGINE" >&2; exit 2; }

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
cd "$T"
mkdir -p src abst/volumes
NG=$(( N > 7 ? N - 7 : 1 )) # contract 条数
for ((i = 1; i <= NG + 6; i++)); do echo "// anchor-a$i" > "src/f$i.ts"; done
jq -n --argjson n "$NG" '{
  version: 1, domains: ["quota"],
  statements: (
    [{id: "MISSION-001", text: "宗旨", level: "mission", feature: "core", signatory: "human", executable: false, weight: 3, version: 1, "derived-from": "spec", boundary: "无", elasticity: "无", "created-at": "2026-08-10T00:00:00.000Z", "impl-refs": ["src/f1.ts"]},
     {id: "MISSION-002", text: "宗旨2", level: "mission", feature: "core", signatory: "human", executable: false, weight: 3, version: 1, "derived-from": "spec", boundary: "无", elasticity: "无", "created-at": "2026-08-10T00:00:00.000Z", "impl-refs": ["src/f2.ts"]}] +
    [range(5) as $g | {id: "G\($g)", text: "目标\($g)", level: "goal", feature: "quota", signatory: "auto", executable: true, weight: 3, version: 1, "derived-from": "spec", boundary: "无", elasticity: "无", refines: ["MISSION-001"], "created-at": "2026-08-10T00:00:00.000Z", "impl-refs": ["src/f\($g+3).ts"]}] +
    [range($n) as $c | {id: "C\($c)", text: "条款\($c)", level: "contract", feature: "quota", signatory: "auto", executable: true, weight: 2, version: 1, "derived-from": "spec", boundary: "无", elasticity: "无", refines: ["G\($c % 5)"], "created-at": "2026-08-10T00:00:00.000Z", "impl-refs": ["src/f\($c+7).ts"],
      evidence: [{id: "e-unit-\($c)", form: "unit", status: "official", file: "src/f\($c+7).ts", marker: "anchor-a\($c+7)"}, {id: "e-e2e-\($c)", form: "e2e", status: "official", resultsFile: "abst/volumes/c\($c).json"}]}]
  )
}' > abst/registry.json
for ((i = 0; i < NG; i++)); do printf '{"pass": true}' > "abst/volumes/c$i.json"; done
IDS="MISSION-001,MISSION-002,G0,G1,G2,G3,G4"
for ((i = 0; i < NG; i++)); do IDS="$IDS,C$i"; done
"$ENGINE" endorse --ids "$IDS" --by bench >/dev/null

bench() { # $1=标签 $2...=命令（gate 转人工等非零退出为正常业务结果，只计时）
  local label="$1"; shift
  local s e rc=0
  s=$(date +%s%N)
  "$@" >/dev/null 2>&1 || rc=$?
  e=$(date +%s%N)
  awk -v rc="$rc" "BEGIN{printf \"%-10s %.2fs（exit %d）\n\", \"$label\", ($e - $s) / 1000000000, rc}"
}
echo "规模：$((NG + 7)) 条声明，$((NG * 2)) 份证据"
bench verify "$ENGINE" verify
bench report "$ENGINE" report
bench "gate --all" "$ENGINE" gate --all
