---
name: write-article
description: 文章写作。根据模板和资料，采用"大纲先行+按章检索"策略生成文章，产出 Markdown 草稿和 Word 文档。
---

# Skill: write-article（文章写作）

## 核心策略

- **大纲先行**：先根据模板生成完整 Markdown 大纲，再逐章扩展。避免一次性吞咽所有资料导致上下文爆炸。
- **按章检索**：每写一个章节时，只读取与该章节相关的资料文件。
- **内容与样式解耦**：LLM 只产出纯净 Markdown，最终用 pandoc + .dotx 模板转换为 .docx。

## 输入

- `template`: 模板文档路径（`templates/<name>-template.md`）
- `materials_dir`: 资料目录路径
- `output_dir`: 输出目录（默认 `output/`）
- `output_name`: 输出文件名前缀
- `topic`: 文章主题
- `dotx`: .dotx 参考模板路径（可选）

## 执行步骤

### Step 0：读取模板，提取写作规范

1. 完整读取 `templates/<name>-template.md`
2. 将以下要素提炼为「写作准则」清单：
   - 章节结构（哪些章节必须有，层级关系）
   - 样式要求（字体、字号、间距——这些在 pandoc 转换时生效）
   - 措辞规范（语气、人称、句式）
   - 关键约束（必须包含/不能包含）

### Step 1：生成大纲（关键步骤）

**1.1 浏览资料目录**
- 列出 `materials_dir/` 下所有文件
- 读取每个文件的标题和元数据（不读正文）
- 读取 `sources.md`（如果存在），获取资料概览

**1.2 生成资料地图**
将每个资料标注为：文件路径、标题、来源、类型（官方文档/博客/讨论/论文）、覆盖主题

**1.3 生成大纲**
根据模板结构 + 资料地图，生成详细大纲并保存：

```bash
# 大纲保存路径
outline_path = "output/<output_name>-outline.md"
```

大纲格式：
```markdown
# 大纲：<文章标题>
生成时间：<ISO 8601>
模板：<template_path>

## 写作准则
- 语气：<...>
- 人称：<...>
- 必须包含章节：<...>

## 资料概览
| # | 文件 | 来源 | 类型 | 覆盖主题 |
|---|------|------|------|----------|

## 章节规划
### 第一章：<章节标题>（对应模板：<章节名>）
- 核心论点：<...>
- 需要的资料：<source-N.md>
- 预计篇幅：约 X 段

### 第二章：<章节标题>（对应模板：<章节名>）
...
```

**1.4 向用户展示大纲**，等待确认后继续。用户说"继续"/"确认"即可进入 Step 2。

### Step 2：逐章写作

对大纲中的每一章，执行：

**2.1 按章检索**
只在 `materials_dir/` 中读取当前章节标注的「需要的资料」文件。如果检索不到足够信息，用 Grep 按关键词搜索其他资料。

**2.2 写作该章**
写出该章的 Markdown 内容，严格遵循：
- 模板指定的标题层级
- 模板指定的措辞风格
- 资料中的具体事实和数据

**2.3 自检**
写完每章后立即检查：
- 标题层级是否与模板一致？
- 是否引用了资料中的具体内容（不是泛泛而谈）？
- 是否有实质性内容（不是一两句话）？
- 是否有"在当今时代""随着...的发展"等空话？

自检通过后，将该章追加到 `output/<output_name>-draft.md`。

### Step 3：全文统稿

1. 通读完整的 `output/<output_name>-draft.md`
2. 检查：
   - 章间过渡是否自然（承上启下）
   - 术语是否统一（同一概念用同一词）
   - 逻辑是否连贯（没有前后矛盾）
   - 是否漏掉了某个必须包含的章节
3. 必要时微调

### Step 4：转换为 .docx

```bash
if [ -n "<dotx_path>" ] && [ -f "<dotx_path>" ]; then
  pandoc "output/<output_name>-draft.md" --reference-doc="<dotx_path>" -o "output/<output_name>.docx"
else
  pandoc "output/<output_name>-draft.md" -o "output/<output_name>.docx"
fi
```

转换后验证：
```bash
python .claude/skills/docx/scripts/office/validate.py "output/<output_name>.docx"
```

## 产出

| 文件 | 路径 |
|------|------|
| 大纲 | `output/<output_name>-outline.md` |
| Markdown 草稿 | `output/<output_name>-draft.md` |
| Word 文档 | `output/<output_name>.docx` |

## 关键约束

- **绝对禁止**一次性读取所有资料文件（防止上下文爆炸和 Lost in the Middle）
- 大纲阶段只读资料的文件列表和元数据（sources.md），不读正文
- 写作阶段每章只能检索该章相关的资料文件
- 不编造数据、URL、人名、引用来源
- 每章写完后立即自检，不要攒到最后
- 如果资料不足支撑某章，在大纲中标注"资料不足"并提示用户补充

## 禁止行为

- 不要跳过 Step 1 大纲直接开始写作
- 不要一次性读取超过 5 个资料文件
- 不要使用 docx-js 生成文档（pandoc + .dotx 是唯一转换路径）
- 不要在未完成统稿前就转换 .docx
- 不要编造资料中不存在的内容

## 硬停止 (Hard Stop)

文章写作完成。
- Markdown 稿：`output/<output_name>-draft.md`
- Word 文档：`output/<output_name>.docx`

**请主流程启动 article-checker subagent 审核此文章。**

**严禁自行进入下一阶段。严禁自行修改文章。**
必须等待 article-checker 审核报告，根据报告修改后重新提交审核。
