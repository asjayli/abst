#!/usr/bin/env bash
# ABST 安装脚本：使 abst 命令全局可用，并（默认）安装 agent skill。
# 兼容 bash >= 3.2。
# 用法：
#   ./install.sh                安装 engine（symlink 到 ~/.local/bin）+ skill（~/.agents/skills/abst）
#   ./install.sh --prefix DIR   指定命令安装目录（默认 ~/.local/bin）
#   ./install.sh --no-skill     只装 engine，不装 skill
#   ./install.sh --force        覆盖已存在的本地修改版 skill
#   ./install.sh uninstall      卸载（skill 目录有本地修改时需 --force）
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="$HOME/.local/bin"
SKILL_DIR="$HOME/.agents/skills/abst"
WITH_SKILL=1
FORCE=0
MODE="install"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) PREFIX="$2"; shift 2;;
    --no-skill) WITH_SKILL=0; shift;;
    --force) FORCE=1; shift;;
    uninstall) MODE="uninstall"; shift;;
    *) echo "未知参数：$1" >&2; exit 2;;
  esac
done

skill_dirty() { # skill 目录存在且与仓库副本不一致 → 0（有本地修改）
  [[ -d "$SKILL_DIR" ]] || return 1
  ! diff -qr "$REPO/skill" "$SKILL_DIR" >/dev/null 2>&1
}

if [[ "$MODE" == "uninstall" ]]; then
  rm -f "$PREFIX/abst"
  if skill_dirty && [[ $FORCE != 1 ]]; then
    echo "✗ $SKILL_DIR 与仓库副本不一致（含本地修改），拒绝删除。确认要删请加 --force。" >&2
    exit 1
  fi
  rm -rf "$SKILL_DIR"
  echo "✓ 已卸载：$PREFIX/abst、$SKILL_DIR"
  exit 0
fi

# 1. 依赖检查
missing=()
for dep in jq sha256sum stat date; do
  command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
done
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "✗ 缺少依赖：${missing[*]}" >&2
  echo "  Debian/Ubuntu: sudo apt install jq coreutils" >&2
  echo "  macOS:         brew install jq coreutils，并把 gnubin 加入 PATH：" >&2
  echo "                 export PATH=\"\$(brew --prefix)/opt/coreutils/libexec/gnubin:\$PATH\"" >&2
  exit 1
fi

# 2. engine：symlink 到 PREFIX
mkdir -p "$PREFIX"
ln -sf "$REPO/bin/abst" "$PREFIX/abst"
echo "✓ engine 已链接：$PREFIX/abst -> $REPO/bin/abst"
case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *) echo "  注意：$PREFIX 不在 PATH 中，请将 export PATH=\"$PREFIX:\$PATH\" 加入 shell 配置";;
esac

# 3. skill
if [[ $WITH_SKILL == 1 ]]; then
  if skill_dirty && [[ $FORCE != 1 ]]; then
    echo "✗ $SKILL_DIR 与仓库副本不一致（含本地修改），拒绝覆盖。确认覆盖请加 --force。" >&2
    exit 1
  fi
  if [[ -d "$SKILL_DIR" ]] && ! skill_dirty; then
    echo "○ skill 已是最新：$SKILL_DIR"
  else
    rm -rf "$SKILL_DIR"
    mkdir -p "$SKILL_DIR"
    cp -r "$REPO/skill/SKILL.md" "$REPO/skill/scripts" "$SKILL_DIR/"
    echo "✓ skill 已安装：$SKILL_DIR"
  fi
fi

# 4. 自检
if "$PREFIX/abst" --version >/dev/null 2>&1; then
  echo "✓ 自检通过：$("$PREFIX/abst" --version)"
else
  echo "✗ 自检失败：$PREFIX/abst 无法执行" >&2
  exit 1
fi
