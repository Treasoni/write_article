#!/usr/bin/env bash
# write_article 结构健康检查
# 用法: bash scripts/lint.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

check() {
    local desc="$1"; shift
    if "$@"; then
        echo "  ✅ $desc"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== write_article 结构检查 ==="
echo ""

# 1. CLAUDE.md 行数限制
echo "--- CLAUDE.md ---"
LINE_COUNT=$(wc -l < CLAUDE.md)
check "CLAUDE.md ≤ 120 行 (当前: $LINE_COUNT)" [ "$LINE_COUNT" -le 120 ]

# 2. CLAUDE.md 中 docs/ 链接有效性
echo ""
echo "--- docs/ 链接有效性 ---"
for f in $(grep -oE 'docs/[a-zA-Z0-9_/.-]+\.md' CLAUDE.md | sort -u || true); do
    if [ -f "$f" ]; then
        echo "  ✅ CLAUDE.md → $f"
        PASS=$((PASS + 1))
    else
        echo "  ❌ CLAUDE.md → $f (文件不存在)"
        FAIL=$((FAIL + 1))
    fi
done

# 3. docs/ 必需文件
echo ""
echo "--- docs/ 必需文件 ---"
REQUIRED_DOCS=("docs/workflow.md" "docs/architecture.md" "docs/principles.md")
for f in "${REQUIRED_DOCS[@]}"; do
    check "$f 存在" [ -f "$f" ]
done

# 4. 必需目录
echo ""
echo "--- 必需目录 ---"
REQUIRED_DIRS=("templates" "materials" "output" "reports" ".learnings" ".claude/agents")
for d in "${REQUIRED_DIRS[@]}"; do
    check "$d/ 存在" [ -d "$d" ]
done

# 5. Agent 文件
echo ""
echo "--- Agent 文件 ---"
REQUIRED_AGENTS=(".claude/agents/article-checker/AGENT.md" ".claude/agents/template-checker/AGENT.md")
for f in "${REQUIRED_AGENTS[@]}"; do
    check "$f 存在" [ -f "$f" ]
done

# 6. docs/ 文件非空
echo ""
echo "--- docs/ 文件非空 ---"
for f in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$f" ]; then
        SIZE=$(wc -c < "$f")
        check "$f 非空 (大小: $SIZE bytes)" [ "$SIZE" -gt 0 ]
    fi
done

# 结果
echo ""
echo "================================="
echo "结果: $PASS 通过, $FAIL 失败"
if [ "$FAIL" -gt 0 ]; then
    echo "❌ 结构检查未通过"
    exit 1
else
    echo "✅ 全部检查通过"
fi
