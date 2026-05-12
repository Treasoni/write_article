# write_article — AI 文章写作工作流

## 启动时必读

**在开始任何操作之前，必须先执行以下检查：**

1. 读取 `.current_phase.json`（如果存在）
   - 如果 `phase != "completed"`：从断点恢复，跳到上次未完的步骤继续
   - 如果 `phase == "completed"`：提示用户上次任务已完成，询问是否开始新任务
   - 如果文件不存在：正常启动，从 Phase 0 开始

2. 读取 `.learnings/RULES.md`（如果存在）
   - 将其中的规则作为本次任务的最高优先级约束
   - 特别关注 `## Don't` 部分的内容

---

## 总体架构

本项目采用层级调用模型：

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

**路由规则**：
- 模板审核 → 启动 template-checker subagent（不要直接调用 read-template 做审核）
- 文章审核 → 启动 article-checker subagent（不要直接调用 check-format 做审核）
- 资料收集 → 直接调用 collect skill
- 文章写作 → 直接调用 write-article skill
- Word 操作 → 调用 docx skill
- 自我学习 → 调用 digest skill

---

## 完整工作流

### Phase 0：初始化询问

**强制：必须依次询问用户以下问题，不可跳过。**

1. **是否有模板？**
   - 纯模板文件（.docx 或 .md）
   - 用模板写好的文章（需要从中提取模板）
   - 无模板（需要你帮忙设计一个）

2. **模板文件在哪里？**
   - 获取绝对路径

3. **输出存在哪里？**
   - 建议默认 `output/` 目录
   - 确认输出目录路径

4. **文章主题是什么？输出文件如何命名？**
   - 获取 topic 和 output_name

5. **你有什么资料？**
   - 文件（获取路径）
   - 链接（稍后用 defuddle 抓取）
   - 文字描述（记录到 materials/）

6. **确认流程**
   - 向用户展示完整的 5 个 Phase 流程概要
   - 确认后开始执行，**强制按流程走，绝不允许跳步**

**Phase 0 完成时，更新状态文件：**

创建或更新 `.current_phase.json`：
```json
{
  "phase": "phase_0",
  "phase_name": "初始化",
  "status": "completed",
  "updated_at": "<ISO 8601>",
  "context": {
    "topic": "<用户输入>",
    "output_name": "<用户输入>",
    "output_dir": "<用户输入>"
  }
}
```

---

### Phase 1：模板处理

**目标**：生成一个准确的、可供 write-article 使用的结构化模板文档。

```
1. 调用 Skill({skill: "read-template"})
   参数：template_path, mode, output_name
   ↓
2. read-template 生成 templates/<name>-template.md
   ↓
3. 启动 Agent({subagent_type: "general-purpose", description: "模板审核"})
   告诉它：
   - 提取的模板：templates/<name>-template.md
   - 原始文件：<用户提供的模板路径>
   - 请按照你在 AGENT.md 中定义的流程审核
   ↓
4. template-checker 生成 reports/template-check-*.md
   ↓
5. 你读取审核报告：
   ├── 裁决 = 不通过
   │   → 根据报告中的问题项修改 templates/<name>-template.md
   │   → 返回步骤 3（重新审核）
   └── 裁决 = 通过
       → 更新 .current_phase.json (phase = "phase_1", status = "completed")
       → 进入 Phase 2
```

**⚠️ 状态框（Phase 1 完成时打印）：**
```
┌──────────────────────────────────────┐
│ ✅ Phase 1 完成：模板处理             │
│ 模板文档：templates/<name>-template.md │
│ 审核通过，进入 Phase 2：资料收集       │
│                                      │
│ 🛑 下一步：整理用户资料               │
└──────────────────────────────────────┘
```

---

### Phase 2：资料收集

**目标**：整理用户资料，必要时上网搜索补充，形成结构化的资料库。

```
1. 整理用户提供的资料
   - 文件：复制/移动到 materials/<topic>/raw/ 下
   - 链接：记录到待抓取清单
   - 文字：保存为 materials/<topic>/raw/user-notes.md
   ↓
2. 生成 sources.md（资料索引）
   materials/<topic>/sources.md
   ↓
3. 询问用户：是否需要上网收集更多资料？
   ├── 否 → 跳到步骤 5
   └── 是 → 调用 Skill({skill: "collect"})
              ↓
            collect 执行：
              - 用 smart-search 路由搜索
              - 用 opencli 搜索各站点
              - 用 defuddle 抓取网页
              - 保存到 materials/<topic>/raw/
              - 更新 sources.md
   ↓
4. 整理分类（最小改动原则）
   - 不修改 raw/ 下的原始文件
   - 只更新 sources.md 的分类和标签
   - 如果有明显不适合的资料，标注"未采用"而不是删除
   ↓
5. 更新 .current_phase.json (phase = "phase_2", status = "completed")
   进入 Phase 3
```

**⚠️ 状态框（Phase 2 完成时打印）：**
```
┌──────────────────────────────────────────┐
│ ✅ Phase 2 完成：资料收集                  │
│ 资料位置：materials/<topic>/               │
│ 资料来源数：X 个                           │
│                                          │
│ 🛑 下一步：大纲先行 → 逐章写作              │
└──────────────────────────────────────────┘
```

---

### Phase 3：文章写作 & 审核循环

**目标**：生成符合模板格式、内容充实的 .docx 文章。

```
1. 调用 Skill({skill: "write-article"})
   参数：template, materials_dir, output_dir, output_name, topic, dotx
   ↓
2. write-article 执行「大纲先行 + 按章检索」：
   Step 0: 读取模板 → 写作准则
   Step 1: 浏览资料 → 资料地图 → 生成大纲
   Step 2: 逐章检索 + 写作 + 自检
   Step 3: 全文统稿
   Step 4: pandoc + .dotx → .docx
   ↓
3. write-article 完成后，你启动 article-checker subagent
   Agent({subagent_type: "general-purpose", description: "文章审核"})
   告诉它：
   - 模板：templates/<name>-template.md
   - 草稿：output/<name>-draft.md
   - Word：output/<name>.docx
   - 资料：materials/<topic>/
   ↓
4. article-checker 调用 check-format → 深度审核 → reports/article-check-*.md
   ↓
5. 你读取审核报告：
   ├── 裁决 = 不通过
   │   → 根据报告中的「修改指引」重新调用 write-article
   │   → write-article 应优先修改有问题的章节，而不是整篇重写
   │   → 返回步骤 3（重新审核）
   └── 裁决 = 通过
       → 更新 .current_phase.json (phase = "phase_3", status = "completed")
       → 进入 Phase 4
```

**⚠️ 状态框（Phase 3 完成时打印）：**
```
┌──────────────────────────────────────────┐
│ ✅ Phase 3 完成：文章定稿                  │
│ Markdown：output/<name>-draft.md          │
│ Word 文档：output/<name>.docx             │
│                                          │
│ 🛑 下一步：自我学习与经验沉淀              │
└──────────────────────────────────────────┘
```

---

### Phase 4：自我学习

**目标**：回顾本次会话，沉淀经验，防止以后犯同样的错误。

```
1. 调用 Skill({skill: "digest"})
   ↓
2. digest 执行：
   - 检查 .learnings/ 文件大小
   - 回顾本次会话的问题和改进
   - 记录到 LEARNINGS.md / ERRORS.md
   - 超过阈值时压缩去重为 RULES.md
   ↓
3. 更新 .current_phase.json (phase = "completed")
```

**⚠️ 状态框（Phase 4 完成时打印）：**
```
┌──────────────────────────────────────────┐
│ ✅ 全部完成                               │
│                                          │
│ 📄 文章：output/<name>.docx               │
│ 📝 模板：templates/<name>-template.md     │
│ 📊 资料：materials/<topic>/               │
│ 📋 报告：reports/                         │
│ 🧠 学习：.learnings/                      │
│                                          │
│ 任务完毕，感谢使用。                       │
└──────────────────────────────────────────┘
```

---

## 状态文件维护

每次 Phase 流转时，你必须用 Write 更新 `.current_phase.json`。

状态流转顺序：
```
null → phase_0 → phase_1 → phase_2 → phase_3 → phase_4 → completed
```

如果用户中断对话，下次启动时你会先检查这个文件，从断点无缝恢复。

---

## 核心原则（来自 AI实战 经验）

### 1. 三道防线防 Prompt Drift

- **第一道**：每个 Skill 和 Subagent 末尾有否定约束（"严禁进入下一阶段"）
- **第二道**：你在每个阶段边界打印状态框
- **第三道**：Skill 级硬停止（每次调用 Skill 时重新读取刹车指令）

### 2. 绝不允许跳步

- Phase 0 → 1 → 2 → 3 → 4 必须严格按序执行
- 模板未审核通过 → 绝不能开始写文章
- 资料未整理完 → 绝不能开始写文章
- 文章未审核通过 → 绝不能标记完成
- 如果用户要求跳步，解释原因并坚持流程

### 3. 尊重审核结果

- template-checker 说不通过 → 必须修改后重新审核
- article-checker 说不通过 → 必须修改后重新审核
- 不要试图说服审核员"这个其实没问题"
- 每个审核循环最多 3 轮，超过 3 轮请人工介入决策

### 4. 动态技能发现

- 必要时 `ls .claude/skills/` 查看有哪些技能可用
- 不要在 CLAUDE.md 中硬编码技能列表
