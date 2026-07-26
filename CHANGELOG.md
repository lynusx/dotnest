# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Git Hook**：新增 `prepare-commit-msg` hook，根据提交信息自动更新版本号
  - `feat(scope):` 提交自动递增 minor 版本
  - `fix(scope):` 提交自动递增 patch 版本
  - `BREAKING CHANGE:` 或 `feat!:` 提交自动递增 major 版本
  - 自动将 `pubspec.yaml` 添加到提交并追加版本更新说明

### Changed

- **UI 全面重新设计**：采用 Material 3 设计规范，重新设计整个应用的视觉风格
  - 更新主题配色方案，主色调为紫蓝色 (#6366F1)
  - 深色侧边栏 (240px) 配合浅色内容区，提供强烈视觉对比
  - 统一使用圆润设计风格 (10-12px 圆角)
  - 三级阴影系统提供深度感
  - 渐变元素：图标容器、页面头部、操作栏背景
  - 所有可交互元素添加悬停动画效果 (150-200ms)
  - 彩色徽章和标签系统用于状态展示
  - 圆形渐变容器的空状态和错误状态设计
  - 重新设计以下页面：
    - API 提取页面：渐变头部、配置面板、统计卡片
    - 设置页面：卡片式布局、可视化字体调节
    - 链接重写页面：统计条、结果列表悬停效果
    - 语雀知识库列表：现代表格设计、点击复制功能
    - 批量上传页面：文件树分组、彩色状态徽章
    - 目录更新页面：文件信息卡片、成功/错误横幅
    - 文档列表页面：带图标的行设计、ID 徽章

### Documentation

- 新增 `UI_REDESIGN.md` 设计系统文档，记录配色方案、组件样式和设计规范

## [0.2.0] - 2026-07-25

### Added

- **链接重写功能**：新增批量重写 Markdown 方括号引用为链接功能
- **全局字号缩放**：新增全局字号缩放设置，可调整默认字体大小
- **语雀导出增强**：
  - 批量创建页新增导出链接按钮
  - 批量创建页新增导出目录按钮
- **目录结构支持**：
  - 扫描预览按源目录结构分组展示
  - 按源目录结构归档生成的 .md 文档
- **API 提取器**：基于 analyzer 包实现 Dart API 文档提取器
- **语雀功能**：
  - 新增 TOC 更新子页面，支持知识库目录同步
  - 支持从本地文件夹批量创建 Markdown 文档

### Fixed

- **语雀导出**：导出链接时跳过无 Front Matter 或缺 title/slug 的文件
- **API 提取优化**：
  - 仅含 library 文档的文件直接展开生成，不归档子目录
  - 构造函数参数映射真实类型，签名代码块保留 dart format 风格
  - 为方法/构造函数/typedef/顶层函数添加签名代码块
  - 修复文档内 Markdown 列表解析，H2 标题改为中文
  - 无公开声明的文件回退提取库级文档注释
- **语雀 TOC**：更新使用原始文件内容配合 jsonEncode

### Changed

- **布局重构**：
  - 使用 NavigationRail 替换自定义侧边栏，设置移至独立页面
  - 语雀子标签页移至侧边栏作为二级项
  - 将并排分割布局替换为 TabBar 布局

### Documentation

- 新增 docs/api-usage 文档优先工作流与文档规范

## [0.1.0] - Initial Release

### Added

- 项目初始化
- 基础 Flutter 桌面应用架构
