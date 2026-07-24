# analyzer用法速查（版本：13.0.0）

## 核心概念

`package:analyzer` 是 Dart 官方的静态分析引擎，能把 Dart 源码解析成 AST（抽象语法树），并可选做类型解析/元素模型（Element）构建。本项目只用其中"解析 + 遍历 AST 提取文档注释、类型签名"的能力（无语义解析），下文速查以此为主，附带跨文件语义解析的入口作对比。

## 常用 API 速查

### 1. parseString / parseFile

- 用途：把一段源码字符串（或某个文件）解析成 `CompilationUnit`（AST 根节点），**不做跨文件类型解析**，性能好，单文件场景首选。
- 代码示例：

```dart
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

// 最简用法：解析源码字符串
final result = parseString(content: sourceCode);
final unit = result.unit; // CompilationUnit

// 完整配置用法
final result = parseString(
  content: sourceCode,
  path: '/abs/path/to/file.dart', // 仅用于错误提示中标注文件名
  featureSet: FeatureSet.latestLanguageVersion(),
  throwIfDiagnostics: false, // false: 有语法错误也不抛异常，自行检查 result.errors
);
if (result.errors.isNotEmpty) {
  for (final e in result.errors) {
    print(e.message);
  }
}
```

> `parseFile({required String path, required FeatureSet featureSet, ...})` 用法一致，区别是直接传文件路径而非已读取的字符串内容。

### 2. CompilationUnit

- 用途：AST 根节点，包含文件的所有顶层声明（`declarations`）与指令（`directives`，如 `import`/`library`）。
- 代码示例：

```dart
final unit = parseString(content: sourceCode).unit;

// 遍历顶层声明
for (final declaration in unit.declarations) {
  print(declaration.runtimeType); // ClassDeclaration / FunctionDeclaration / ...
}

// 遍历指令（如取 library 文档注释）
for (final directive in unit.directives) {
  if (directive is LibraryDirective) {
    print(directive.documentationComment?.tokens);
  }
}
```

### 3. CompilationUnitMember 的 switch 模式匹配

- 用途：`CompilationUnitMember` 是顶层声明的公共接口（`ClassDeclaration`/`MixinDeclaration`/`EnumDeclaration`/`ExtensionDeclaration`/`ExtensionTypeDeclaration`/`TypeAlias`/`FunctionDeclaration`/`TopLevelVariableDeclaration` 等都实现它），用 `switch` + `case X():` 按具体类型分支处理，避免用字符串或正则猜测节点类型。注意它本身**不是** sealed class，`switch` 必须带 `default`（不能保证编译期穷举）。
- 代码示例：

```dart
for (final declaration in unit.declarations) {
  switch (declaration) {
    case ClassDeclaration():
      print('class ${declaration.namePart.typeName.lexeme}');
    case MixinDeclaration():
      print('mixin ${declaration.name.lexeme}');
    case EnumDeclaration():
      print('enum ${declaration.namePart.typeName.lexeme}');
    case FunctionDeclaration():
      print('function ${declaration.name.lexeme}');
    case TypeAlias():
      print('typedef ${declaration.name.lexeme}');
    default:
      break;
  }
}
```

### 4. ClassDeclaration / MixinDeclaration / EnumDeclaration

- 用途：类/mixin/枚举的顶层声明节点，用于取类名、类型参数、继承关系、成员列表。
- 代码示例：

```dart
// 最简用法：取类名
final className = classDeclaration.namePart.typeName.lexeme;

// 完整用法：取类型参数、父类名、成员
final nameWithTypeParams = classDeclaration.namePart.toSource(); // 如 "MyBox<T>"
final superclassName = classDeclaration.extendsClause?.superclass.name.lexeme; // 父类裸类名，无父类为 null
final members = classDeclaration.body.members; // NodeList<ClassMember>

// mixin/enum 同理，注意 mixin 没有 namePart，是 name + typeParameters 分开的
final mixinName = mixinDeclaration.name.lexeme;
final mixinTypeParams = mixinDeclaration.typeParameters?.toSource() ?? '';
```

### 5. ClassMember 的 switch 模式匹配

- 用途：`ClassMember` 是 sealed class，可 `switch` 匹配 `ConstructorDeclaration`/`MethodDeclaration`/`FieldDeclaration`（还有一个较新的 `PrimaryConstructorBody`，对应主构造函数语法），区分构造函数、方法（含 getter/setter/操作符）、字段。建议保留 `default: break;` 分支，避免新增变体时编译失败。
- 代码示例：

```dart
for (final member in classDeclaration.body.members) {
  switch (member) {
    case ConstructorDeclaration():
      final ctorName = member.name?.lexeme ?? 'new'; // 无名构造函数返回 null
      print('constructor $ctorName');
    case MethodDeclaration():
      if (member.isGetter) print('getter ${member.name.lexeme}');
      if (member.isSetter) print('setter ${member.name.lexeme}');
      if (member.isOperator) print('operator ${member.name.lexeme}');
      if (member.isStatic) print('static method ${member.name.lexeme}');
    case FieldDeclaration():
      for (final variable in member.fields.variables) {
        print('field ${member.fields.type?.toSource()} ${variable.name.lexeme}');
      }
    default:
      break;
  }
}
```

### 6. FormalParameter 及子类型（this.x / super.x / 普通参数）

- 用途：`FormalParameter` 是 sealed class，可精确区分构造函数参数是 `this.x`（`FieldFormalParameter`）、`super.x`（`SuperFormalParameter`）还是普通带类型参数（`RegularFormalParameter`）——这是拿到参数真实类型的关键，因为 `this.x`/`super.x` 在 AST 上没有显式类型标注。
- 代码示例：

```dart
for (final param in constructor.parameters.parameters) {
  switch (param) {
    case FieldFormalParameter():
      // this.x：类型要去同类的 FieldDeclaration 里查
      print('this.${param.name.lexeme}');
    case SuperFormalParameter():
      // super.x：类型要沿继承链去父类构造函数里查
      print('super.${param.name.lexeme}');
    case RegularFormalParameter():
      // 显式类型参数，直接读 type
      print('${param.type?.toSource()} ${param.name?.lexeme}');
  }
  // 通用信息：是否具名/可选/必需，默认值
  print('named=${param.isNamed} required=${param.isRequired}');
  print('default=${param.defaultClause?.value.toSource()}');
}
```

### 7. FormalParameterList（含 `{}` / `[]` 分组信息）

- 用途：构造函数/方法/函数的完整参数列表节点，除了 `parameters` 逐个访问外，还能拿到具名/可选参数分组用的 `{`/`[` 分隔符，用于手动拼接参数列表源码时正确还原分组语法。
- 代码示例：

```dart
final list = constructor.parameters; // FormalParameterList

// 最简用法：整体转回源码文本
final source = list.toSource(); // 如 "({Key? key, String? name})"

// 完整用法：手动拼接（需要改写部分参数时）
final delimiter = list.leftDelimiter?.lexeme; // '{' / '[' / null（全是必需位置参数）
for (final param in list.parameters) {
  final isInOptionalGroup = param.isNamed || param.isOptionalPositional;
  // isInOptionalGroup 为 true 时说明该参数在 delimiter 对应的分组内
}
```

### 8. ConstructorDeclaration.initializers（识别 super(...) 调用）

- 用途：拿到构造函数初始化列表，找出显式的 `super(...)`/`super.named(...)` 调用，从而知道该构造函数实际把 `super.x` 参数转发给了父类的哪个具名构造函数（没有显式 `super(...)` 时默认调用父类无名构造函数）。
- 代码示例：

```dart
for (final initializer in constructor.initializers) {
  if (initializer is SuperConstructorInvocation) {
    // constructorName 为 null 表示调用父类无名构造函数 `super(...)`
    final calledCtorName = initializer.constructorName?.name ?? 'new';
    print('calls super.$calledCtorName(...)');
  }
}
```

### 9. Comment（文档注释提取）

- 用途：`///` 或 `/** */` 文档注释节点，`documentationComment` 属性挂在各类声明/成员上，`tokens` 拿到逐行原始文本（需自行去除 `///`/`*` 前缀）。
- 代码示例：

```dart
final comment = classDeclaration.documentationComment; // Comment?
if (comment != null && !comment.hasNodoc) {
  final lines = comment.tokens.map((t) => t.lexeme).toList();
  // 每行形如 "/// 这是一段说明"，需自行 strip 前缀后拼接
}
```

### 10. AnalysisContextCollection（跨文件语义解析，重量级）

- 用途：当需要真正的类型解析（跨文件找到某个符号的声明、拿到 `DartType`）而不只是 AST 结构时使用；开销远大于 `parseString`，需要目标是一个可解析的 Dart/Flutter 包（有 `pubspec.yaml` 且已执行 `pub get`）。
- 代码示例：

```dart
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';

// 最简用法：单文件语义解析
final result = await resolveFile(path: '/abs/path/to/file.dart');
if (result is ResolvedUnitResult) {
  final unit = result.unit; // 已解析类型信息的 CompilationUnit
}

// 完整用法：批量解析多个文件（性能更好，resolveFile 内部提示只解析一个文件时才用它）
final collection = AnalysisContextCollection(
  includedPaths: ['/abs/path/to/package_root'],
);
try {
  final context = collection.contextFor('/abs/path/to/package_root/lib/foo.dart');
  final session = context.currentSession;
  final result = await session.getResolvedUnit('/abs/path/to/package_root/lib/foo.dart');
  if (result is ResolvedUnitResult) {
    final unit = result.unit;
  }
} finally {
  await collection.dispose(); // 必须调用，释放底层资源
}
```

## 选型建议

| 场景 | 推荐 API |
| --- | --- |
| 只需要 AST 结构（提取文档注释、遍历声明、拼接签名文本），不关心跨文件类型 | `parseString` / `parseFile` |
| 需要知道某个符号（如 `super.key`）的真实类型，且符号可能在其他文件/包里声明 | `AnalysisContextCollection` + `session.getResolvedUnit` |
| 只解析单个文件的语义信息，且只调用一次 | `resolveFile`（内部对多文件场景效率低，仅适合一次性单文件） |

本项目的 `lib/features/extract/service/dart_analyzer_service.dart` 目前采用 `parseString` 方案：先对目录下所有文件跑一遍 `parseString` 建立一个手写的"类名 → 字段类型/构造函数参数"索引，再据此解析 `this.x`/`super.x` 的真实类型——在不引入 `AnalysisContextCollection` 重量级依赖的前提下，覆盖了本项目实际需要的跨文件类型解析场景。
