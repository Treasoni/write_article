# 完整工作流

> 本文档由 CLAUDE.md 拆分而来。进入任何 Phase 前，你【必须】调用 Read 工具读取本文档中对应章节。严禁凭记忆执行。

---

## Phase 0：初始化询问

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

## Phase 1：模板处理

**目标**：生成一个准确的、可供 write-article 使用的结构化模板文档。

```
1. 调用 Skill({skill: "read-template"})
   参数：template_path, mode, output_name
   ↓
2. read-template 生成 templates/<name>-template.md
   ↓
3. 启动 template-checker subagent 审核
   告诉它：
   - 提取的模板：templates/<name>-template.md
   - 原始文件：<用户提供的模板路径>
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

**Phase 1 完成时打印状态框：**
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

## Phase 2：资料收集

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

**Phase 2 完成时打印状态框：**
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

## Phase 3：文章写作 & 审核循环

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
3. write-article 完成后，启动 article-checker subagent
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

**Phase 3 完成时打印状态框：**
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

## Phase 4：自我学习

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

**Phase 4 完成时打印状态框：**
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
