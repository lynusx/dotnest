# yaml 用法速查（版本：3.1.3）

## 核心概念

`package:yaml` 是 Dart 官方的 YAML 解析库，将 YAML 文本解析为 `YamlMap`/`YamlList`/标量等只读节点类型。本项目用其解析"调整分类"功能的分组配置文件与 Markdown Front Matter。

## 常用 API 速查

### 1. loadYaml

- 用途：将 YAML 字符串解析为 Dart 对象（映射根节点返回 `YamlMap`，列表根节点返回 `YamlList`）。解析失败抛出 `YamlException`。
- 代码示例：

```dart
import 'package:yaml/yaml.dart';

final doc = loadYaml(yamlContent);
if (doc is! YamlMap) {
  throw const FormatException('根节点必须是映射结构');
}
```

- 注意事项：`YamlException` 未在 `yaml.dart` 之外的 catch 子句中特别处理时，用通用 `catch (e)` 捕获并转换为业务错误信息即可。

### 2. YamlMap 递归遍历

- 用途：`YamlMap.entries` 与标准 `Map` 一致，可递归处理任意深度的嵌套映射；`YamlList` 支持 `for..in` 直接遍历元素。
- 代码示例：

```dart
void walk(YamlMap map, List<String> path) {
  for (final entry in map.entries) {
    final key = entry.key.toString();
    final value = entry.value;
    if (value is YamlList) {
      for (final item in value) {
        print('leaf ${item.toString()} at ${[...path, key]}');
      }
    } else if (value is YamlMap) {
      walk(value, [...path, key]);
    }
  }
}
```

- 注意事项：`YamlMap` 的 key 类型是 `dynamic`（YAML 支持非字符串 key），业务侧一律通过 `.toString()` 归一化为字符串再使用。

## 典型场景模式

### 场景：将多层级分组 YAML 解析为「叶子节点 → 目录路径段」映射

```yaml
Future与异步计算:
  核心类型与工具:
    - Future
    - Completer
```

```dart
Map<String, List<String>> parseConfig(String yamlContent) {
  final doc = loadYaml(yamlContent);
  if (doc is! YamlMap) {
    throw const FormatException('配置文件根节点必须是映射结构');
  }
  final result = <String, List<String>>{};
  void walk(YamlMap map, List<String> pathSegments) {
    for (final entry in map.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      final newPath = [...pathSegments, key];
      if (value is YamlList) {
        for (final item in value) {
          result[item.toString()] = newPath;
        }
      } else if (value is YamlMap) {
        walk(value, newPath);
      }
    }
  }
  walk(doc, []);
  return result;
}
// parseConfig(...) => {'Future': ['Future与异步计算', '核心类型与工具'], ...}
```

### 场景：从 Markdown Front Matter 中提取 title 字段

```dart
String? extractTitle(String content) {
  if (!content.startsWith('---')) return null;
  final fmEnd = content.indexOf('\n---', 3);
  if (fmEnd == -1) return null;
  final fmBlock = content.substring(3, fmEnd);
  final doc = loadYaml(fmBlock);
  if (doc is YamlMap) {
    final title = doc['title'];
    if (title != null) return title.toString();
  }
  return null;
}
```
