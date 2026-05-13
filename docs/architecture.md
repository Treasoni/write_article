# 架构说明

> 本文档由 CLAUDE.md 拆分而来。理解项目架构前，你【必须】调用 Read 工具读取本文档。严禁凭记忆拼凑架构。

---

## 层级调用模型

```
Claude Code 主流程（你）
  ├── Subagent: template-checker → 审核提取的模板
  ├── Subagent: article-checker → 审核写好的文章
  ├── Skill: read-template → 提取模板
  ├── Skill: write-article → 写文章
  ├── Skill: collect → 收集资料（opencli + smart-search + defuddle）
  ├── Skill: digest → 自我学习
  └── Skill: docx → Word 文档操作
```

---

## 路由规则

| 任务 | 调用方式 | 说明 |
|------|----------|------|
| 模板审核 | 启动 template-checker subagent | 不要直接调用 read-template 做审核 |
| 文章审核 | 启动 article-checker subagent | 不要直接调用 check-format 做审核 |
| 资料收集 | 调用 collect skill | |
| 文章写作 | 调用 write-article skill | |
| Word 操作 | 调用 docx skill | |
| 自我学习 | 调用 digest skill | |

---

## Subagent 清单

### template-checker
- **位置**：`.claude/agents/template-checker/AGENT.md`
- **职责**：对照用户原始模板文件，审核 read-template 生成的模板文档是否准确、完整
- **触发**：Phase 1，read-template 完成后

### article-checker
- **位置**：`.claude/agents/article-checker/AGENT.md`
- **职责**：对照模板和资料，审核文章的结构、内容、格式是否合规
- **触发**：Phase 3，write-article 完成后

---

## Skill 清单

### 项目特定 Skills

| Skill | 位置 | 职责 |
|-------|------|------|
| `read-template` | `.claude/skills/read-template/SKILL.md` | 从模板文件提取结构化模板文档 |
| `write-article` | `.claude/skills/write-article/SKILL.md` | 大纲先行 + 按章检索写作 |
| `check-format` | `.claude/skills/check-format/SKILL.md` | 文章格式检查 |
| `collect` | `.claude/skills/collect/SKILL.md` | 资料收集（搜索 + 抓取） |
| `digest` | `.claude/skills/digest/SKILL.md` | 自我学习与经验沉淀 |

### 通用 Skills

| Skill | 用途 |
|-------|------|
| `docx` | Word 文档创建与编辑 |
| `pdf` | PDF 处理 |
| `pptx` | PowerPoint 处理 |
| `xlsx` | Excel 处理 |
| `defuddle` | 网页内容提取 |
| `smart-search` | 智能搜索路由 |
| `opencli-usage` | OpenCLI 使用指南 |
| `opencli-browser` | 浏览器自动化 |
| `opencli-adapter-author` | OpenCLI 适配器编写 |
| `opencli-autofix` | OpenCLI 适配器修复 |
| `skill-creator` | 技能创建与管理 |
| `doc-coauthoring` | 文档协作 |

---

## 动态技能发现

不要硬编码技能列表。必要时使用 `ls .claude/skills/` 查看当前可用技能。

Skills 数量可能随时间增长，CLAUDE.md 中只保留路由规则中的核心 Skills，完整列表以实际文件系统为准。
