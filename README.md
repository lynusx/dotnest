# DotNest

一款桌面端（Windows / macOS）工具应用，用于从 Dart 项目源码中提取 API 定义信息，并将提取结果同步至语雀（Yuque）知识库。

## 核心功能

### 1. Dart API 文档提取

- 基于 `analyzer` 包进行词法分析，精确提取 Dart 源码中的 API 定义
- 支持提取类、方法、构造函数、typedef、顶层函数等声明
- 自动生成包含签名代码块的 Markdown 文档
- 按源目录结构归档生成的文档
- 智能处理库级文档注释

### 2. 语雀知识库同步

- 从本地文件夹批量创建 Markdown 文档至语雀知识库
- 支持知识库目录（TOC）同步更新
- 导出功能：
  - 批量导出文档链接
  - 批量导出目录结构
- 扫描预览按源目录结构分组展示

### 3. Markdown 工具

- 批量重写 Markdown 方括号引用为链接
- 支持自定义链接重写规则

### 4. 界面与设置

- 基于 NavigationRail 的侧边栏导航
- 全局字号缩放设置
- 独立的设置页面

## 技术栈

### UI 框架

- **Flutter SDK**：跨平台桌面应用开发
- **Material 组件库**：统一使用 Flutter 内置 Material 风格

### 核心依赖

| 依赖                  | 版本      | 用途               |
| --------------------- | --------- | ------------------ |
| `flutter_screenutil` | ^5.9.3    | UI 适配            |
| `provider`            | ^6.1.5+1  | 状态管理           |
| `dio`                 | ^5.10.0   | HTTP 网络请求      |
| `retrofit`            | ^4.9.2    | RESTful API 封装   |
| `go_router`           | ^17.3.0   | 路由管理           |
| `shared_preferences`  | ^2.5.5    | 本地存储           |
| `path_provider`       | ^2.1.6    | 路径访问           |
| `file_picker`         | ^11.0.2   | 文件选择           |
| `analyzer`            | ^13.0.0   | Dart 源码词法分析  |
| `dart_style`          | ^3.1.9    | Dart 代码格式化    |

## 架构设计

采用 **MVVM** 架构模式：

- **Model**：纯数据结构与业务实体
- **View**：UI 渲染与交互事件转发
- **ViewModel**：状态管理与业务逻辑

## 开发规范

1. **UI 组件**：统一使用 Flutter SDK 内置 Material 组件库，禁止混用其他 UI 库
2. **词法分析**：必须使用 `analyzer` 包，严禁使用正则表达式解析 Dart 源码
3. **第三方依赖**：优先复用现有依赖，新增依赖需征得确认
4. **代码分层**：严格遵循 MVVM 分层约定，View 禁止直接调用 Repository

详细开发规范请参阅 `.claude/CLAUDE.md`。

## 快速开始

### 环境要求

- Flutter SDK: ^3.12.2
- Dart SDK: ^3.12.2

### 安装依赖

```bash
flutter pub get
```

### 代码生成

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 运行应用

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

## 项目结构

```
lib/
├── models/          # 数据模型
├── viewmodels/      # 视图模型
├── views/           # UI 视图
├── services/        # 业务服务
├── repositories/    # 数据仓库
└── utils/           # 工具函数

docs/
└── api-usage/       # 第三方包用法文档

refer/
└── yuque_openapi.md # 语雀 OpenAPI 参考文档
```

## 版本历史

查看 [CHANGELOG.md](CHANGELOG.md) 了解版本更新详情。

## 许可证

本项目仅供个人学习与研究使用。
