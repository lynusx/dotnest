import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../model/extract_result.dart';

/// Dart 源码分析服务，基于 package:analyzer 的 AST 解析提取文档注释
class DartAnalyzerService {
  // ── 公开入口 ────────────────────────────────────────────────────────────────

  /// 扫描 [sourceDir] 下所有 .dart 文件，提取 API 文档，输出到 [outputDir]
  Future<List<ExtractResult>> extractFromDirectory(
    String sourceDir,
    String outputDir,
  ) async {
    final results = <ExtractResult>[];
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final files = await _collectDartFiles(sourceDir);
    final usedFileNames = <String>{};

    for (final file in files) {
      try {
        final content = await file.readAsString();
        final fileResults = _processFile(
          content,
          file.path,
          outputDir,
          usedFileNames,
        );
        for (final r in fileResults) {
          final outputFile = File('$outputDir/${r.result.fileName}');
          await outputFile.writeAsString(r.markdown);
          results.add(r.result);
        }
      } catch (e) {
        results.add(
          ExtractResult(
            apiName: file.uri.pathSegments.last,
            fileName: '',
            apiType: ApiType.classType,
            sourcePath: file.path,
            success: false,
            error: e.toString(),
          ),
        );
      }
    }
    return results;
  }

  // ── 文件收集 ────────────────────────────────────────────────────────────────

  Future<List<File>> _collectDartFiles(String sourceDir) async {
    final dir = Directory(sourceDir);
    if (!await dir.exists()) return [];
    final files = <File>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      final name = entity.uri.pathSegments.last;
      if (name.startsWith('_')) continue;
      final p = entity.path.replaceAll('\\', '/');
      if (p.contains('/generated/') ||
          p.contains('/build/') ||
          p.contains('/test/')) {
        continue;
      }
      files.add(entity);
    }
    return files;
  }

  // ── 文件级处理（AST 解析） ───────────────────────────────────────────────────

  List<_ExtractResultInternal> _processFile(
    String content,
    String sourcePath,
    String outputDir,
    Set<String> usedFileNames,
  ) {
    if (!content.contains('///') && !content.contains('/**')) return [];

    final unit = parseString(
      content: content,
      path: sourcePath,
      featureSet: FeatureSet.latestLanguageVersion(),
      throwIfDiagnostics: false,
    ).unit;

    final results = <_ExtractResultInternal>[];
    for (final declaration in unit.declarations) {
      for (final api in _extractApis(declaration)) {
        final fileName = _uniqueFileName(api.name, usedFileNames);
        final markdown = _buildMarkdown(api);
        results.add(
          _ExtractResultInternal(
            ExtractResult(
              apiName: api.name,
              fileName: fileName,
              apiType: api.type,
              sourcePath: sourcePath,
              success: true,
            ),
            markdown,
          ),
        );
      }
    }

    if (results.isEmpty) {
      final libraryDoc = _extractLibraryDoc(unit);
      if (libraryDoc != null) {
        final baseName = _baseName(sourcePath);
        final fileName = _uniqueFileName(baseName, usedFileNames);
        results.add(
          _ExtractResultInternal(
            ExtractResult(
              apiName: baseName,
              fileName: fileName,
              apiType: ApiType.library,
              sourcePath: sourcePath,
              success: true,
            ),
            '$libraryDoc\n',
          ),
        );
      }
    }

    return results;
  }

  /// 无公开声明时，从 `library` 指令上的文档注释中提取库级说明
  String? _extractLibraryDoc(CompilationUnit unit) {
    for (final directive in unit.directives) {
      if (directive is! LibraryDirective) continue;
      return _docText(directive.documentationComment);
    }
    return null;
  }

  /// 取源文件名（去除目录与 `.dart` 后缀），用于库级文档同名输出
  String _baseName(String sourcePath) {
    final normalized = sourcePath.replaceAll('\\', '/');
    final fileName = normalized.substring(normalized.lastIndexOf('/') + 1);
    return fileName.endsWith('.dart')
        ? fileName.substring(0, fileName.length - 5)
        : fileName;
  }

  // ── 顶层声明 → API 信息 ──────────────────────────────────────────────────────

  List<_ApiInfo> _extractApis(CompilationUnitMember declaration) {
    switch (declaration) {
      case ClassDeclaration():
        return _classLikeApi(
          name: declaration.namePart.typeName.lexeme,
          type: ApiType.classType,
          docComment: declaration.documentationComment,
          members: declaration.body.members,
        );
      case MixinDeclaration():
        return _classLikeApi(
          name: declaration.name.lexeme,
          type: ApiType.mixin,
          docComment: declaration.documentationComment,
          members: declaration.body.members,
        );
      case EnumDeclaration():
        return _enumApi(declaration);
      case ExtensionDeclaration():
        final nameToken = declaration.name;
        if (nameToken == null) return const [];
        return _classLikeApi(
          name: nameToken.lexeme,
          type: ApiType.extension,
          docComment: declaration.documentationComment,
          members: declaration.body.members,
        );
      case TypeAlias():
        return _leafApi(
          name: declaration.name.lexeme,
          type: ApiType.typedef,
          docComment: declaration.documentationComment,
        );
      case FunctionDeclaration():
        return _leafApi(
          name: declaration.name.lexeme,
          type: ApiType.function,
          docComment: declaration.documentationComment,
        );
      case TopLevelVariableDeclaration():
        return _topLevelVariableApis(declaration);
      default:
        return const [];
    }
  }

  List<_ApiInfo> _leafApi({
    required String name,
    required ApiType type,
    required Comment? docComment,
  }) {
    if (name.startsWith('_')) return const [];
    final doc = _docText(docComment);
    if (doc == null) return const [];
    return [
      _ApiInfo(name: name, type: type, docComment: doc, members: const []),
    ];
  }

  List<_ApiInfo> _classLikeApi({
    required String name,
    required ApiType type,
    required Comment? docComment,
    required NodeList<ClassMember> members,
  }) {
    if (name.startsWith('_')) return const [];
    final doc = _docText(docComment);
    if (doc == null) return const [];
    return [
      _ApiInfo(
        name: name,
        type: type,
        docComment: doc,
        members: _extractMembers(members),
      ),
    ];
  }

  List<_ApiInfo> _enumApi(EnumDeclaration declaration) {
    final name = declaration.namePart.typeName.lexeme;
    if (name.startsWith('_')) return const [];
    final doc = _docText(declaration.documentationComment);
    if (doc == null) return const [];

    final members = <_MemberInfo>[];
    for (final constant in declaration.body.constants) {
      final constName = constant.name.lexeme;
      if (constName.startsWith('_')) continue;
      members.add(
        _MemberInfo(
          name: constName,
          category: MemberCategory.enumValues,
          docComment: _docText(constant.documentationComment) ?? '',
          isOverride: false,
        ),
      );
    }
    members.addAll(_extractMembers(declaration.body.members));

    return [
      _ApiInfo(
        name: name,
        type: ApiType.enumType,
        docComment: doc,
        members: members,
      ),
    ];
  }

  List<_ApiInfo> _topLevelVariableApis(
    TopLevelVariableDeclaration declaration,
  ) {
    final doc = _docText(declaration.documentationComment);
    if (doc == null) return const [];
    final apis = <_ApiInfo>[];
    for (final variable in declaration.variables.variables) {
      final name = variable.name.lexeme;
      if (name.startsWith('_')) continue;
      apis.add(
        _ApiInfo(
          name: name,
          type: ApiType.variable,
          docComment: doc,
          members: const [],
        ),
      );
    }
    return apis;
  }

  // ── 成员提取（类型判断，非文本匹配） ─────────────────────────────────────────

  List<_MemberInfo> _extractMembers(NodeList<ClassMember> members) {
    final out = <_MemberInfo>[];
    for (final member in members) {
      switch (member) {
        case ConstructorDeclaration():
          final doc = _docText(member.documentationComment);
          if (doc == null) break;
          out.add(
            _MemberInfo(
              name: member.name?.lexeme ?? 'new',
              category: MemberCategory.constructors,
              docComment: doc,
              isOverride: false,
            ),
          );
        case MethodDeclaration():
          if (member.name.lexeme.startsWith('_')) break;
          final doc = _docText(member.documentationComment);
          if (doc == null) break;
          out.add(
            _MemberInfo(
              name: member.name.lexeme,
              category: _methodCategory(member),
              docComment: doc,
              isOverride: _hasOverride(member.metadata),
              readWriteStatus: member.isGetter ? 'no setter' : null,
            ),
          );
        case FieldDeclaration():
          final doc = _docText(member.documentationComment);
          if (doc == null) break;
          for (final variable in member.fields.variables) {
            final name = variable.name.lexeme;
            if (name.startsWith('_')) continue;
            out.add(
              _MemberInfo(
                name: name,
                category: member.isStatic
                    ? MemberCategory.staticProperties
                    : MemberCategory.instanceProperties,
                docComment: doc,
                isOverride: _hasOverride(member.metadata),
              ),
            );
          }
        default:
          break;
      }
    }
    _mergeGetterSetter(out);
    return out;
  }

  MemberCategory _methodCategory(MethodDeclaration member) {
    if (member.isOperator) return MemberCategory.operators;
    if (member.isGetter || member.isSetter) {
      return member.isStatic
          ? MemberCategory.staticProperties
          : MemberCategory.instanceProperties;
    }
    return member.isStatic
        ? MemberCategory.staticMethods
        : MemberCategory.instanceMethods;
  }

  bool _hasOverride(NodeList<Annotation> metadata) {
    for (final annotation in metadata) {
      if (annotation.name.name == 'override') return true;
    }
    return false;
  }

  /// getter/setter 合并：若已有 getter，更新 readWrite；若只有 setter 删除
  void _mergeGetterSetter(List<_MemberInfo> members) {
    final getters = <String, int>{};
    final setters = <String, int>{};

    for (var i = 0; i < members.length; i++) {
      final m = members[i];
      if (m.category == MemberCategory.instanceProperties ||
          m.category == MemberCategory.staticProperties) {
        if (m.readWriteStatus == 'no setter') {
          getters[m.name] = i;
        } else if (m.docComment.isEmpty) {
          setters[m.name] = i;
        }
      }
    }

    final toRemove = <int>[];
    for (final entry in setters.entries) {
      final name = entry.key;
      final setterIdx = entry.value;
      if (getters.containsKey(name)) {
        final getterIdx = getters[name]!;
        members[getterIdx] = members[getterIdx].withReadWrite(
          'getter/setter pair',
        );
        toRemove.add(setterIdx);
      }
    }

    for (final idx in toRemove.reversed) {
      members.removeAt(idx);
    }
  }

  // ── 文档注释文本提取（基于 AST token，非文本行扫描） ─────────────────────────

  String? _docText(Comment? comment) {
    if (comment == null || comment.hasNodoc) return null;
    final rawLines = <String>[];
    for (final token in comment.tokens) {
      final lexeme = token.lexeme;
      if (lexeme.startsWith('///')) {
        rawLines.add(_stripLineComment(lexeme));
      } else {
        rawLines.addAll(lexeme.split('\n').map(_stripBlockLine));
      }
    }
    final text = _joinDocLines(rawLines).trim();
    return text.isEmpty ? null : text;
  }

  /// 去掉 `///` 前缀及紧随其后的单个分隔空格，其余缩进（如代码示例）原样保留
  String _stripLineComment(String lexeme) {
    final rest = lexeme.substring(3);
    return rest.startsWith(' ') ? rest.substring(1) : rest;
  }

  /// 去掉 `/**`/`*/`/行首 `*` 及紧随其后的单个分隔空格，其余缩进原样保留
  String _stripBlockLine(String line) {
    var s = line.trimLeft();
    if (s.startsWith('/**')) {
      s = s.substring(3);
    } else if (s.startsWith('/*')) {
      s = s.substring(2);
    } else if (s.startsWith('*/')) {
      return '';
    } else if (s.startsWith('*')) {
      s = s.substring(1);
    }
    if (s.startsWith(' ')) s = s.substring(1);
    final closeIdx = s.indexOf('*/');
    if (closeIdx != -1) {
      s = s.substring(0, closeIdx);
      if (s.endsWith(' ')) s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// 将同一段落内的多行合并为一行；保留空行分段、围栏代码块内的原始换行/缩进，
  /// 并正确处理 Markdown 列表项（`*`/`-` 统一转为 `-`，每项独占一行）与
  /// dartdoc 模板标签行（如 `{@tool ...}`/`{@end-tool}`，独占一行不参与合并）
  String _joinDocLines(List<String> rawLines) {
    final out = <String>[];
    var inFence = false;
    String? paragraph;

    void flushParagraph() {
      if (paragraph != null) {
        out.add(paragraph!);
        paragraph = null;
      }
    }

    for (final line in rawLines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        flushParagraph();
        out.add(line);
        inFence = !inFence;
        continue;
      }
      if (inFence) {
        out.add(line);
        continue;
      }
      if (trimmed.isEmpty) {
        flushParagraph();
        out.add('');
        continue;
      }
      if (_isTemplateTagLine(trimmed)) {
        flushParagraph();
        out.add(trimmed);
        continue;
      }
      final listItemText = _stripListMarker(trimmed);
      if (listItemText != null) {
        flushParagraph();
        paragraph = '- $listItemText';
        continue;
      }
      paragraph = paragraph == null ? trimmed : '$paragraph $trimmed';
    }
    flushParagraph();
    return out.join('\n');
  }

  /// dartdoc 模板标签行，如 `{@tool dartpad}`、`{@end-tool}`、`{@macro foo}`
  bool _isTemplateTagLine(String trimmed) =>
      trimmed.startsWith('{@') && trimmed.endsWith('}');

  /// 若 [trimmed] 是 `*`/`-` 加空格开头的 Markdown 列表项，返回去掉标记后的正文
  String? _stripListMarker(String trimmed) {
    if (trimmed.startsWith('* ')) return trimmed.substring(2);
    if (trimmed.startsWith('- ')) return trimmed.substring(2);
    return null;
  }

  // ── Markdown 生成 ───────────────────────────────────────────────────────────

  String _buildMarkdown(_ApiInfo api) {
    final buf = StringBuffer();

    buf.writeln('---');
    buf.writeln('title: ${api.name}');
    buf.writeln('slug: ${api.name}-${api.type.keyword}');
    buf.writeln('---');
    buf.writeln();
    buf.writeln(api.docComment);
    buf.writeln();

    final grouped = _groupMembers(api.members);
    const order = [
      MemberCategory.enumValues,
      MemberCategory.constructors,
      MemberCategory.staticProperties,
      MemberCategory.staticMethods,
      MemberCategory.instanceProperties,
      MemberCategory.instanceMethods,
      MemberCategory.operators,
    ];

    for (final cat in order) {
      final list = grouped[cat];
      if (list == null || list.isEmpty) continue;

      if (api.type == ApiType.enumType &&
          (cat == MemberCategory.constructors ||
              cat == MemberCategory.staticProperties ||
              cat == MemberCategory.staticMethods ||
              cat == MemberCategory.operators)) {
        continue;
      }

      buf.writeln('## ${_categoryTitle(cat)}');
      buf.writeln();
      for (final m in list) {
        buf.writeln('### ${m.name}');
        if (m.isOverride) buf.writeln('override');
        if (m.readWriteStatus != null) buf.writeln(m.readWriteStatus);
        if (m.docComment.isNotEmpty) buf.writeln(m.docComment);
        buf.writeln();
      }
    }

    return buf.toString();
  }

  Map<MemberCategory, List<_MemberInfo>> _groupMembers(
    List<_MemberInfo> members,
  ) {
    final grouped = <MemberCategory, List<_MemberInfo>>{};
    for (final m in members) {
      grouped.putIfAbsent(m.category, () => []).add(m);
    }

    for (final cat in grouped.keys) {
      if (cat == MemberCategory.enumValues) continue; // 保持原序
      if (cat == MemberCategory.constructors) {
        grouped[cat]!.sort((a, b) {
          if (a.name == 'new') return -1;
          if (b.name == 'new') return 1;
          return a.name.compareTo(b.name);
        });
      } else {
        grouped[cat]!.sort((a, b) => a.name.compareTo(b.name));
      }
    }
    return grouped;
  }

  String _categoryTitle(MemberCategory cat) => switch (cat) {
    MemberCategory.enumValues => '枚举值',
    MemberCategory.constructors => '构造函数',
    MemberCategory.staticProperties => '静态属性',
    MemberCategory.staticMethods => '静态方法',
    MemberCategory.instanceProperties => '实例属性',
    MemberCategory.instanceMethods => '实例方法',
    MemberCategory.operators => '操作符',
  };

  // ── 文件名唯一化 ─────────────────────────────────────────────────────────────

  String _uniqueFileName(String apiName, Set<String> used) {
    String name = '$apiName.md';
    int n = 2;
    while (used.contains(name)) {
      name = '${apiName}_$n.md';
      n++;
    }
    used.add(name);
    return name;
  }
}

// ── 内部数据结构 ──────────────────────────────────────────────────────────────

class _ApiInfo {
  final String name;
  final ApiType type;
  final String docComment;
  final List<_MemberInfo> members;
  const _ApiInfo({
    required this.name,
    required this.type,
    required this.docComment,
    required this.members,
  });
}

class _MemberInfo {
  final String name;
  final MemberCategory category;
  final String docComment;
  final bool isOverride;
  final String? readWriteStatus;

  const _MemberInfo({
    required this.name,
    required this.category,
    required this.docComment,
    required this.isOverride,
    this.readWriteStatus,
  });

  _MemberInfo withReadWrite(String status) => _MemberInfo(
    name: name,
    category: category,
    docComment: docComment,
    isOverride: isOverride,
    readWriteStatus: status,
  );
}

enum MemberCategory {
  enumValues,
  constructors,
  staticProperties,
  staticMethods,
  instanceProperties,
  instanceMethods,
  operators,
}

/// 内部扩展，携带生成的 Markdown 内容
class _ExtractResultInternal {
  final ExtractResult result;
  final String markdown;
  const _ExtractResultInternal(this.result, this.markdown);
}
