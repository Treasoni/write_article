# 任务进度跟踪

> 此文件由 AI 自动维护。每完成一个子步骤，必须在此打勾。进入下一阶段前，必须读取此文件确认上一步已完成。

---

## 阶段一：初始化 (Phase 0)
- [ ] 询问用户需求（模板、输出路径、主题、资料）
- [ ] 获取模板路径
- [ ] 获取输出目录路径
- [ ] 获取文章主题和文件名
- [ ] 获取资料信息
- [ ] 向用户确认完整流程
- [ ] 更新 `.current_phase.json` 为 phase_0 completed

## 阶段二：模板处理 (Phase 1)
- [ ] 调用 read-template 提取模板
- [ ] 启动 template-checker 审核
- [ ] 根据审核结果修改（如有）
- [ ] 更新 `.current_phase.json` 为 phase_1 completed

## 阶段三：资料收集 (Phase 2)
- [ ] 整理用户资料到 materials/ 目录
- [ ] 生成 sources.md 资料索引
- [ ] 可选：上网补充资料
- [ ] 更新 `.current_phase.json` 为 phase_2 completed

## 阶段四：文章写作 (Phase 3)
- [ ] 调用 write-article 生成大纲
- [ ] 用户确认大纲
- [ ] 逐章写作完成
- [ ] 启动 article-checker 审核
- [ ] 根据审核结果修改（如有）
- [ ] 生成 .docx 文件
- [ ] 更新 `.current_phase.json` 为 phase_3 completed

## 阶段五：自我学习 (Phase 4)
- [ ] 调用 digest 沉淀经验
- [ ] 更新 `.current_phase.json` 为 completed

---

## 进度日志

| 时间 | 阶段 | 操作 | 结果 |
|------|------|------|------|
| | | | |
