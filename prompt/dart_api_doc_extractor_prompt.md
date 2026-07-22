# Dart API 文档提取器

## 任务目标
递归扫描指定目录下的所有 `.dart` 文件，提取公开 API 的文档注释，生成结构化的 Markdown 文档，输出格式对齐 Dart 官方 API 文档（api.flutter.dev）的页面结构。

## 输入
- `source_dir`: Dart 源码目录路径（递归扫描）
- `output_dir`: Markdown 输出目录路径

## 处理规则

### 1. 文件筛选
- 仅处理 `.dart` 文件
- 跳过以下文件：
  - 以 `_` 开头的私有文件
  - `generated/`、`build/`、`test/` 目录下的文件
  - 不含任何文档注释（`///` 或 `/** */`）的文件

### 2. API 识别（仅提取公开 API）
提取以下类型的**公开**声明（非下划线开头）：
- `class`
- `mixin`
- `enum`
- `extension`（仅带 `on` 的**有名称**公开扩展；匿名扩展跳过）
- `typedef`
- 顶层 `function`
- 顶层 `variable` / `constant`（`variable` 指顶层 `final`/普通变量，`constant` 指顶层 `const` 声明；二者处理方式完全一致，仅概念区分）

**排除**：
- 私有成员（以下划线 `_` 开头）
- 局部变量、局部函数
- 匿名函数
- 非公开的类/枚举/混入等
- 带有 `{@nodoc}` 标签的 API 及其所有子成员（整个 API 跳过，不生成文件）

  > `{@nodoc}` 是写在**文档注释内部**的 dartdoc 指令，例如：
  >
  > ```dart
  > /// {@nodoc}
  > class InternalHelper { ... }
  > ```
  > 它不是独立的 Dart 元数据注解（区别于写在声明上方单独一行的 `@override` 等 annotation）。判断时应检查文档注释正文中是否包含 `{@nodoc}` 字样，而非检查声明上方是否有 `@nodoc` 注解行。

### 3. 文档注释提取
- 仅提取紧接在声明前的文档注释（`///` 或 `/** ... */`）
- 保留原始 Markdown 格式和代码块（包括 ```dart 等语言标识）
- 保留文档注释中的 `[ClassName]`、`[ClassName.member]` 等引用语法，不做修改或删除
- 忽略普通注释（`//` 或 `/* */`）

### 4. 成员提取范围（⚠️ 关键规则，已简化）

**只处理在当前文件中有文本声明的成员，不考虑继承关系，不追溯父类/接口/mixin 所在的其他文件。**

- **保留**：当前文件的类/mixin/enum/extension 声明体内，**出现文本声明**的成员——无论该声明是否带函数体（含抽象方法、接口式声明 `void foo();`）、无论是否带 `@override` 注解
- **排除**：当前文件声明体内**完全没有出现任何文本声明**的成员（即该成员只存在于其他文件的父类/接口/mixin 源码中，当前文件没有重复写出它）

**判定规则**：
- 只要成员的声明文本（哪怕只有签名、没有函数体）出现在当前文件的声明体内，就提取它；不需要判断这个成员"最初"是否来自父类、也不需要读取父类所在的文件
- 是否带函数体、是否带 `@override` 注解，都不影响"是否提取"，只影响第 8 节的成员标记
- 由于工具本来就只逐文件扫描，"排除"这一条通常会自然成立（其他文件里的成员本来就不会出现在当前文件的声明体内），这里明确写出只是为避免歧义

  > 示例：`abstract class Foo { /// 说明\n void bar(); }` 中的 `bar` 应保留——声明写在当前文件里，只是没有函数体。

### 5. 成员筛选规则（⚠️ 关键规则）

**仅提取有文档注释的成员。**

- **保留**：成员声明前有文档注释（`///` 或 `/** ... */`）的成员
- **排除**：成员声明前**无文档注释**的成员

**判定规则**：
- 检查成员声明前的连续注释块，若存在文档注释则保留
- 若成员仅有普通注释（`//` 或 `/* */`），视为无文档注释，排除
- 若成员无任何注释，排除
- 此规则适用于所有成员类型：构造函数、属性、方法、运算符等

**例外**：
- enum 的 value：即使无文档注释，也**保留**（value 名称本身具有语义价值）
- 但无文档注释的 value，H3 下方内容为空

### 6. 成员分类与排序（按 API 类型区分）

#### 6.1 Class / Mixin 类型的成员分类

| 顺序 | H2 标题 | 包含内容 | 排序规则 |
|------|---------|----------|----------|
| 1 | `## Constructors` | 有文档注释的构造函数（含 `factory` 构造函数） | 无名构造函数排最前；其余（含具名、factory）按"点号后的具名部分"字母顺序排序，不含类名前缀 |
| 2 | `## Static Properties` | 有文档注释的 `static` 字段/属性 | 字母顺序 |
| 3 | `## Static Methods` | 有文档注释的 `static` 方法 | 字母顺序 |
| 4 | `## Instance Properties` | 有文档注释的实例字段/属性 | 字母顺序 |
| 5 | `## Instance Methods` | 有文档注释的实例方法 | 字母顺序 |
| 6 | `## Operators` | 有文档注释的运算符重载 | 字母顺序 |

**getter/setter 特殊处理**：
- 若属性同时有 getter 和 setter，仅提取 getter 的文档注释
- 将 getter/setter 视为一个 Instance Property，不重复列出
- 若 getter 无文档注释，整个属性排除（即使 setter 有文档注释也不例外）

#### 6.2 Enum 类型的成员分类

| 顺序 | H2 标题 | 包含内容 | 排序规则 |
|------|---------|----------|----------|
| 1 | `## Values` | 所有 enum value（无论是否有文档注释） | **按源代码声明顺序** |
| 2 | `## Properties` | 有文档注释的实例属性 | 字母顺序 |
| 3 | `## Methods` | 有文档注释的实例方法 | 字母顺序 |

**Enum 类型不生成以下 H2**：
- `## Constructors`
- `## Static Properties`
- `## Static Methods`
- `## Operators`
- `## Constants`

#### 6.3 其他 API 类型

| API 类型 | 成员分类方式 |
|----------|-------------|
| `extension` | 同 class，仅保留有文档注释的成员 |
| `typedef` | 无成员，仅提取类型别名本身的文档注释 |
| `function`（顶层） | 无成员，仅提取函数本身的文档注释和签名 |
| `variable` / `constant`（顶层） | 无成员，仅提取变量/常量本身的文档注释和类型 |

### 7. Markdown 文件生成

#### 文件命名
- 每个公开 API 生成一个独立的 `.md` 文件
- 文件名格式：`{API名称}.md`
- 泛型参数**不保留**在文件名中，如 `List.md` 而非 `List<T>.md`
- 文件名非法字符处理：泛型尖括号 `<>`（及其中内容）整体移除；其余操作系统文件名非法字符（如 `/ \ : * ? " < > |`）统一替换为 `-`
- **同名冲突处理**：若 `source_dir` 内不同文件产生同名 `.md`（如两个不同库中都有 `class Options`），按扫描顺序为后出现者追加数字后缀（`Options_2.md`、`Options_3.md` ……），**不做静默覆盖**；同时在扫描日志中输出冲突提示，列出两个来源文件路径

#### Front Matter（YAML，位于文件顶部）
```yaml
---
title: {API名称}
slug: {API名称}-{类型关键字}
---
```

**类型关键字映射**：
| API 类型 | slug 后缀 |
|----------|-----------|
| class | `class` |
| mixin | `mixin` |
| enum | `enum` |
| extension | `extension` |
| typedef | `typedef` |
| function | `function` |
| variable/constant | `variable` |

#### 正文结构

```markdown
---
title: {API名称}
slug: {API名称}-{类型关键字}
---

{API 描述段落（保留完整文档注释，包括 See also、代码示例等）}

## Values（仅 enum）

### valueName
{文档注释内容（若有）}

## Constructors（class/mixin/extension）

### constructorName
{文档注释内容}

## Static Properties（class/mixin/extension）

### propertyName
{读写状态标记}
{文档注释内容}

## Static Methods（class/mixin/extension）

### methodName
{文档注释内容}

## Instance Properties（class/mixin/enum/extension）

### propertyName
{读写状态标记}
{文档注释内容}

## Instance Methods（class/mixin/enum/extension）

### methodName
{文档注释内容}

## Operators（class/mixin/extension）

### operatorName
{文档注释内容}
```

**格式要求**：
- **不生成 H1 标题**（Front Matter 的 title 已标识 API 名称，避免重复）
- H2 为成员类型分类标题
- **H3 标题仅为成员名称**，不包含类型签名、参数列表、返回类型
- H3 下方紧跟成员标记（若有），再下方为文档注释内容
- 若某类别下无成员，则省略该 H2 标题
- 若某 H2 下所有成员均无文档注释（enum 的 Values 除外），则省略该 H2 标题
- 若 API 本身有文档注释但所有成员均无文档注释：仍生成文件，仅包含 Front Matter + 描述部分，不含任何 H2
- 文档注释中的代码块保持原始缩进和语言标识
- 保留 `[ClassName]`、`[ClassName.member]` 等引用语法

### 8. 成员标记规则

每个成员在 H3 标题下方、文档注释内容上方标注以下标记（如有）：

| 标记 | 含义 | 判定方式 |
|------|------|----------|
| `override` | 该成员声明处带有 `@override` 注解 | 只检测当前文件中声明上方是否写了 `@override`，不需要验证父类中是否真的存在同名成员 |
| `no setter` | 只读属性 | 当前文件中该属性只有 getter，没有对应 setter |
| `getter/setter pair` | 可读写属性 | 当前文件中该属性同时有 getter 和对应 setter |

**注意**：不标注 `inherited`（当前文件中没有声明的成员本来就不会被提取，因此也不存在"仅继承"这种需要特别标注的情况）

### 9. 输出目录结构
```
{output_dir}/
├── AnimationEagerListenerMixin.md
├── MainAlignment.md
├── SomeClass.md
└── ...
```

### 10. 库级文档注释（可选）
- 若文件顶部存在 library 指令前的文档注释，可额外生成一个索引文件（非强制）
- 索引文件命名：统一使用 `{library_name}_index.md`；仅当整个 `source_dir` 范围内只扫描到单一顶层库时，才可以简化命名为 `index.md`（避免多个 library 共用 `index.md` 互相覆盖）

## 边界情况处理

> 以下仅列出未在正文规则中说明、或需要额外强调的情况。与正文重复的判定（如 `{@nodoc}`、匿名扩展、getter/setter 合并、抽象方法归属、无文档注释成员排除等）不再重复列出，请参见对应章节。

1. **空目录/无 dart 文件**：输出空目录，不报错
2. **enum 只有一个 value**：仍生成 Values H2
3. **API 本身无文档注释**：整个 API 跳过，不生成文件（区别于"成员无文档注释"，后者只排除该成员，不影响整个 API 是否生成文件）

## 示例

### 示例 1：Class

**输入 Dart 代码**：
```dart
/// A mixin that eagerly listens to animation notifications.
mixin AnimationEagerListenerMixin {
  /// Creates a new instance.
  AnimationEagerListenerMixin();

  /// This implementation ignores listener registrations.
  void didRegisterListener() {}

  /// Release the resources used by this object.
  void dispose() {}
}
```

**输出文件 `AnimationEagerListenerMixin.md`**：
```markdown
---
title: AnimationEagerListenerMixin
slug: AnimationEagerListenerMixin-mixin
---

A mixin that eagerly listens to animation notifications.

## Constructors

### AnimationEagerListenerMixin
Creates a new instance.

## Instance Methods

### didRegisterListener
This implementation ignores listener registrations.

### dispose
Release the resources used by this object.
```

**注意**：
- 无 H1 标题
- H3 仅为成员名称（如 `### AnimationEagerListenerMixin`、`### didRegisterListener`），不包含签名

### 示例 2：Enum

**输入 Dart 代码**：
```dart
/// How the children should be placed along the main axis in a flex layout.
enum MainAlignment {
  /// Place the children as close to the start of the main axis as possible.
  start,

  end,

  /// Place the children as close to the middle of the main axis as possible.
  center,

  spaceBetween,
}
```

**输出文件 `MainAlignment.md`**：
```markdown
---
title: MainAlignment
slug: MainAlignment-enum
---

How the children should be placed along the main axis in a flex layout.

## Values

### start
Place the children as close to the start of the main axis as possible.

### end

### center
Place the children as close to the middle of the main axis as possible.

### spaceBetween
```

**注意**：
- 无 H1 标题
- H3 仅为 value 名称（如 `### start`、`### end`），不包含 `→ const MainAlignment`
- `end` 和 `spaceBetween` 无文档注释，H3 下方为空

### 示例 3：带 @override 标记的成员

**输入 Dart 代码**：
```dart
/// A custom animation controller.
class MyAnimationController extends AnimationController {
  /// Creates a new instance.
  MyAnimationController();

  /// Custom dispose logic.
  @override
  void dispose() {}

  /// Custom string representation.
  @override
  String toString() => 'MyAnimationController';
}
```

**输出文件 `MyAnimationController.md`**：
```markdown
---
title: MyAnimationController
slug: MyAnimationController-class
---

A custom animation controller.

## Constructors

### MyAnimationController
Creates a new instance.

## Instance Methods

### dispose
override
Custom dispose logic.

### toString
override
Custom string representation.
```

**注意**：
- 无 H1 标题，也不再输出 Inheritance 信息（v7 起不处理继承链）
- H3 仅为 `### dispose`、`### toString`，不包含签名
- `override` 标记的判定只看当前文件中是否写了 `@override` 注解，不需要知道 `AnimationController` 的源码

### 示例 4：抽象方法声明

**输入 Dart 代码**：
```dart
/// A widget that has a mutable state.
abstract class StatefulWidget {
  /// Creates the mutable state for this widget at a given location in the tree.
  State createState();
}
```

**输出文件 `StatefulWidget.md`**：

```markdown
---
title: StatefulWidget
slug: StatefulWidget-class
---

A widget that has a mutable state.

## Instance Methods

### createState
Creates the mutable state for this widget at a given location in the tree.
```

**注意**：
- `createState` 只有签名、没有函数体（以 `;` 结尾），但其声明文本出现在当前文件中，因此**保留**
