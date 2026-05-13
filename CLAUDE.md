# write_article — AI 文章写作工作流

## 启动时必读

在开始任何操作之前，你【必须】按顺序执行以下检查：

1. 读取 `.current_phase.json`（如果存在）
   - `phase != "completed"` → 从断点恢复，跳到上次未完的步骤继续
   - `phase == "completed"` → 提示用户上次任务已完成，询问是否开始新任务
   - 文件不存在 → 从 Phase 0 开始

2. 读取 `.learnings/RULES.md`（如果存在）
   - 将其中的规则作为本次任务的最高优先级约束
   - 特别关注 `## Don't` 部分

---

## 总体架构

```
Claude Code 主流程（你）
  ├── Subagent: template-checker → 审核提取的模板
  ├── Subagent: article-checker → 审核写好的文章
  ├── Skill: read-template → 提取模板
  ├── Skill: write-article → 写文章
  ├── Skill: collect → 收集资料
  ├── Skill: digest → 自我学习
  └── Skill: docx → Word 文档操作
```

---

## 路由规则

| 任务 | 调用方式 | 禁止 |
|------|----------|------|
| 模板审核 | 启动 template-checker subagent | 不要直接调用 read-template 做审核 |
| 文章审核 | 启动 article-checker subagent | 不要直接调用 check-format 做审核 |
| 资料收集 | 调用 collect skill | |
| 文章写作 | 调用 write-article skill | |
| Word 操作 | 调用 docx skill | |
| 自我学习 | 调用 digest skill | |

---

## Phase 导航

**【强制】进入任何 Phase 前，你【必须】调用 Read 工具读取 `docs/workflow.md` 中对应章节。严禁凭记忆执行。**

```
Phase 0: 初始化询问   →  收集用户需求（主题、模板、资料、输出）
Phase 1: 模板处理     →  提取模板 → 审核通过
Phase 2: 资料收集     →  整理资料 + 可选上网搜索
Phase 3: 写作 & 审核  →  大纲先行 → 逐章写作 → 审核 → 修改循环
Phase 4: 自我学习     →  沉淀经验，更新 RULES.md
```

流程细节、状态框格式、JSON 示例 → 见 `docs/workflow.md`

---

## 状态文件维护

每次 Phase 流转时，用 Write 更新 `.current_phase.json`。

```
null → phase_0 → phase_1 → phase_2 → phase_3 → phase_4 → completed
```

中断恢复由 `.current_phase.json` 保证。

---

## 核心原则

1. **三道防线防 Prompt Drift**：Skill 否定约束 + 状态框 + 硬停止
2. **绝不允许跳步**：模板未审 → 不写；资料未齐 → 不写；文章未审 → 不定稿
3. **尊重审核结果**：不通过必须修改，最多 3 轮，不要说服审核员
4. **最小改动原则**：不改原始文件，只改索引；优先修章节，不整篇重写

**【强制】做任何涉及流程、架构或原则的决策前，你【必须】调用 Read 工具读取 `docs/principles.md` 全文。违反任一条都可能导致任务失败。**

---

## 文档索引

| 文档 | 内容 | 何时读取 |
|------|------|----------|
| `docs/workflow.md` | Phase 0~4 完整流程 | 进入任何 Phase 前 |
| `docs/architecture.md` | 架构、Skills、Agents 详解 | 需要了解架构时 |
| `docs/principles.md` | 核心原则 + 反面案例 | 做决策前 |

**【强制】你需要通过 Read 工具逐字阅读上面的文档，不要把链接当作你在训练数据中见过的文件名去猜测执行。**
