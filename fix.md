# 新增功能

归扫描指定文件夹下的所有 .md / .markdown 文件，将正文（排除 YAML Front Matter 和代码块）中由 [] 包裹的内容，按以下优先级规则替换为带链接的 Markdown 语法。

## 输入

1. target_dir: 待处理的文件夹（递归扫描所有子目录）,弹窗选择
2. url_map.json：URL映射文件，弹窗选择，格式如下：

```json
{
  "StatelessWidget": "https://www.yuque.com/flutter/StatelessWidget",
  "BuildContext": "https://www.yuque.com/flutter/BuildContext",
  "Scaffold": "https://www.yuque.com/flutter/Scaffold"
}
```

## 处理规则（严格按优先级执行）

### 规则1: JSON映射匹配（最高优先级）

扫描正文中的 [X] 或 [X.anchor] 形式文本：

- 若 X 存在于 url_map.json 的键中：
  - [x] → [X](url_map[X])
  - [X.anchor] → [X.anchor](url_map[X]#anchor)
  - 已有的markdown链接 → 按 url_map.json 更新
- 若不存在，进入规则 2
- 注意：匹配严格区分大小写

### 规则2: 本文件 H3 标题锚点匹配（次优先级）

若规则 1 未命中，检查当前文件的 H3 标题（### Title）：

- 若存在 H3 标题 ### build，则：
  - [build] → [build](#build)
- 若不存在对应 H3 标题，保持 [build] 原样不变
- 注意：仅匹配 H3（###），不匹配 H1/H2/H4+

### 规则3: 无匹配（保持原样）

若以上规则均未命中，保留原始 [X] 文本不变，不做任何修改。

## 保护区域（禁止修改）

以下区域内的 [...] 内容不得替换：

1. YAML Front Matter（--- 包裹的头部元数据）
2. 代码块（``` 或 ~~~ 包裹的区域）
3. 行内代码（`...`）

## 输出要求

1. 直接覆盖原文件（或输出到新目录，保持原目录结构）
2. 保持原始文件的换行、缩进和空行不变
3. 仅修改匹配到的 [X] 文本，其余内容原样保留
4. 处理完成后，输出处理摘要：
   - 扫描文件总数
   - 成功处理文件数
   - 各文件替换次数统计

## 示例

### 输入文件

```json
{
  "StatelessWidget": "https://www.yuque.com/flutter/StatelessWidget",
  "BuildContext": "https://www.yuque.com/flutter/BuildContext",
  "Scaffold": "https://www.yuque.com/flutter/Scaffold"
}
```

````markdown
---
title: Builder
slug: Builder-class
---

A stateless utility widget whose [build] method uses its [builder] callback to create the widget's child.

This widget is an inline alternative to defining a [StatelessWidget] subclass. For example, instead of defining a widget as follows:

```dart
class Foo extends StatelessWidget {
  const Foo({super.key});
  @override
  Widget build(BuildContext context) => const Text('foo');
}
```

...and using it in the usual way:

```dart
// continuing from previous example...
const Center(child: Foo())
```

...one could instead define and use it in a single step, without defining a new widget class:

```dart
Center(
  child: Builder(
    builder: (BuildContext context) => const Text('foo'),
  ),
)
```

The difference between either of the previous examples and creating a child directly without an intervening widget, is the extra [BuildContext] element that the additional widget adds. This is particularly noticeable when the tree contains an inherited widget that is referred to by a method like [Scaffold.of], which visits the child widget's BuildContext ancestors.

In the following example the button's `onPressed` callback is unable to find the enclosing [ScaffoldState] with [Scaffold.of]:

```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () {
          // Fails because Scaffold.of() doesn't find anything
          // above this widget's context.
          print(Scaffold.of(context).hasAppBar);
        },
        child: const Text('hasAppBar'),
      )
    ),
  );
}
```

A [Builder] widget introduces an additional [BuildContext] element and so the [Scaffold.of] method succeeds.

```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: Builder(
      builder: (BuildContext context) {
        return Center(
          child: TextButton(
            onPressed: () {
              print(Scaffold.of(context).hasAppBar);
            },
            child: const Text('hasAppBar'),
          ),
        );
      },
    ),
  );
}
```

See also:

- [StatefulBuilder], A stateful utility widget whose [build] method uses its [builder] callback to create the widget's child.

## 构造函数

### new

```dart
const Builder({Key? key, required WidgetBuilder builder})
```

Creates a widget that delegates its build to a callback.

## 实例属性

### builder

Called to obtain the child widget.

This function is called whenever this widget is included in its parent's build and the old widget (if any) that it synchronizes with has a distinct object identity. Typically the parent's build method will construct a new tree of widgets and so a new Builder child will not be [identical] to the corresponding old one.
````

### 处理后输出

````markdown
---
title: Builder
slug: Builder-class
---

A stateless utility widget whose [build] method uses its [builder](#builder) callback to create the widget's child.

This widget is an inline alternative to defining a [StatelessWidget](https://www.yuque.com/flutter/StatelessWidget) subclass. For example, instead of defining a widget as follows:

```dart
class Foo extends StatelessWidget {
  const Foo({super.key});
  @override
  Widget build(BuildContext context) => const Text('foo');
}
```

...and using it in the usual way:

```dart
// continuing from previous example...
const Center(child: Foo())
```

...one could instead define and use it in a single step, without defining a new widget class:

```dart
Center(
  child: Builder(
    builder: (BuildContext context) => const Text('foo'),
  ),
)
```

The difference between either of the previous examples and creating a child directly without an intervening widget, is the extra [BuildContext](https://www.yuque.com/flutter/BuildContext) element that the additional widget adds. This is particularly noticeable when the tree contains an inherited widget that is referred to by a method like [Scaffold.of](https://www.yuque.com/flutter/Scaffold#of), which visits the child widget's BuildContext ancestors.

In the following example the button's `onPressed` callback is unable to find the enclosing [ScaffoldState] with [Scaffold.of](https://www.yuque.com/flutter/Scaffold#of):

```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () {
          // Fails because Scaffold.of() doesn't find anything
          // above this widget's context.
          print(Scaffold.of(context).hasAppBar);
        },
        child: const Text('hasAppBar'),
      )
    ),
  );
}
```

A [Builder] widget introduces an additional [BuildContext]https://www.yuque.com/flutter/BuildContext element and so the [Scaffold.of](https://www.yuque.com/flutter/Scaffold#of) method succeeds.

```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: Builder(
      builder: (BuildContext context) {
        return Center(
          child: TextButton(
            onPressed: () {
              print(Scaffold.of(context).hasAppBar);
            },
            child: const Text('hasAppBar'),
          ),
        );
      },
    ),
  );
}
```

See also:

- [StatefulBuilder], A stateful utility widget whose [build] method uses its [builder](#builder) callback to create the widget's child.

## 构造函数

### new

```dart
const Builder({Key? key, required WidgetBuilder builder})
```

Creates a widget that delegates its build to a callback.

## 实例属性

### builder

Called to obtain the child widget.

This function is called whenever this widget is included in its parent's build and the old widget (if any) that it synchronizes with has a distinct object identity. Typically the parent's build method will construct a new tree of widgets and so a new Builder child will not be [identical] to the corresponding old one.
````

## 注意事项

- 严格区分大小写：[statelesswidget] 与 [StatelessWidget] 视为不同文本
- 锚点符号仅支持 .（如 [Scaffold.of]），转换为 #of
- 若 JSON 和 H3 同时存在同名键，JSON 优先级更高

规则2生成的本地锚点 #xxx，当 H3 标题包含空格/大写字母时如何生成锚点文本？ → 保持不变

修复：
在导出链接时，若一个markdown文件没有Front Matter（或没有title、slug字段），则跳过处理该文件

## 提交时自动更新版本号

实现说明：

1. Hook 类型：prepare-commit-msg - 在提交信息准备好后自动执行
2. 版本更新规则（遵循语义化版本）：
   - feat(scope): → 递增 minor 版本（0.2.0 → 0.3.0）
   - fix(scope): → 递增 patch 版本（0.2.0 → 0.2.1）
   - BREAKING CHANGE: 或 feat!: → 递增 major 版本（0.2.0 → 1.0.0）
   - 其他类型（chore/docs/refactor）→ 不更新版本

3. 自动操作：
   - 更新 pubspec.yaml 中的版本号
   - 自动将 pubspec.yaml 添加到本次提交
   - 在提交信息末尾追加版本更新说明

4. 文档：在 .git/hooks/README.md 中记录了使用说明
debugtest
debug2
