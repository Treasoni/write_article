# write_article — AI 文章写作工作流

基于 Claude Code 的多阶段文章写作系统，采用"大纲先行 + 按章检索"策略，支持模板驱动、资料收集、自动审核和 Word 文档生成。

## 项目结构

```
write_article/
├── CLAUDE.md              # 项目指令（~100 行地图）
├── docs/                  # 详细文档
│   ├── workflow.md        # Phase 0~4 完整流程
│   ├── architecture.md    # 架构、Skills、Agents
│   └── principles.md      # 核心原则 + 反面案例
├── scripts/               # 工具脚本
│   └── lint.sh            # 结构健康检查
├── templates/             # 结构化模板文档
├── materials/             # 按主题组织的资料库
│   └── <topic>/
│       ├── raw/           # 原始资料
│       └── sources.md     # 资料索引
├── output/                # 文章产出（.md + .docx）
├── reports/               # 审核报告
└── .learnings/            # 经验沉淀（RULES.md / ERRORS.md）
```

## 工作流概览

```
Phase 0: 初始化询问   →  收集用户需求（主题、模板、资料、输出）
Phase 1: 模板处理     →  提取模板 → 审核通过
Phase 2: 资料收集     →  整理资料 + 可选上网搜索
Phase 3: 写作 & 审核  →  大纲先行 → 逐章写作 → 审核 → 修改循环
Phase 4: 自我学习     →  沉淀经验，更新 RULES.md
```

每个 Phase 严格按序执行，不可跳步。断点恢复机制通过 `.current_phase.json` 实现。详细流程见 `docs/workflow.md`。

## 架构

采用层级调用模型，主流程协调 Skills 和 Subagents：

| 角色 | 名称 | 职责 |
|------|------|------|
| Skill | `read-template` | 从模板文件提取结构化模板 |
| Skill | `write-article` | 大纲先行 + 按章检索写作 |
| Skill | `collect` | 智能搜索 + 资料抓取 |
| Skill | `digest` | 会话回顾 + 经验沉淀 |
| Skill | `docx` | Word 文档生成与操作 |
| Subagent | `template-checker` | 模板合规审核 |
| Subagent | `article-checker` | 文章内容与格式审核 |

完整架构文档见 `docs/architecture.md`。

## 快速开始

1. 在 Claude Code 中打开本项目
2. 按 CLAUDE.md 指引，从 Phase 0 开始交互
3. 提供文章主题、模板、资料，跟随流程完成写作

## 结构检查

```bash
bash scripts/lint.sh
```

验证 CLAUDE.md 行数限制、docs/ 文件完整性、目录结构等。
