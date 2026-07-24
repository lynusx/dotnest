import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_style/dart_style.dart';

import '../model/extract_result.dart';

/// Dart 源码分析服务，基于 package:analyzer 的 AST 解析提取文档注释
class DartAnalyzerService {
  final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

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
    final parsedFiles = <_ParsedFile>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final unit = parseString(
          content: content,
          path: file.path,
          featureSet: FeatureSet.latestLanguageVersion(),
          throwIfDiagnostics: false,
        ).unit;
        parsedFiles.add(_ParsedFile(file.path, unit));
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

    final classIndex = _buildClassIndex(parsedFiles);
    final usedFileNames = <String>{};

    for (final pf in parsedFiles) {
      try {
        final fileResults = _processFile(
          pf.unit,
          pf.sourcePath,
          usedFileNames,
          classIndex,
        );
        for (final r in fileResults) {
          final outputFile = File('$outputDir/${r.result.fileName}');
          await outputFile.writeAsString(r.markdown);
          results.add(r.result);
        }
      } catch (e) {
        results.add(
          ExtractResult(
            apiName: _baseName(pf.sourcePath),
            fileName: '',
            apiType: ApiType.classType,
            sourcePath: pf.sourcePath,
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
    CompilationUnit unit,
    String sourcePath,
    Set<String> usedFileNames,
    Map<String, _ClassIndexEntry> classIndex,
  ) {
    final results = <_ExtractResultInternal>[];
    for (final declaration in unit.declarations) {
      for (final api in _extractApis(declaration, classIndex)) {
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

  List<_ApiInfo> _extractApis(
    CompilationUnitMember declaration,
    Map<String, _ClassIndexEntry> classIndex,
  ) {
    switch (declaration) {
      case ClassDeclaration():
        final bareName = declaration.namePart.typeName.lexeme;
        return _classLikeApi(
          name: bareName,
          type: ApiType.classType,
          docComment: declaration.documentationComment,
          members: declaration.body.members,
          bareClassName: bareName,
          classIndex: classIndex,
        );
      case MixinDeclaration():
        return _classLikeApi(
          name: declaration.name.lexeme,
          type: ApiType.mixin,
          docComment: declaration.documentationComment,
          members: declaration.body.members,
          bareClassName: declaration.name.lexeme,
          classIndex: classIndex,
        );
      case EnumDeclaration():
        return _enumApi(declaration, classIndex);
      case ExtensionDeclaration():
        final nameToken = declaration.name;
        if (nameToken == null) return const [];
        return _classLikeApi(
          name: nameToken.lexeme,
          type: ApiType.extension,
          docComment: declaration.documentationComment,
          members: declaration.body.members,
          bareClassName: nameToken.lexeme,
          classIndex: classIndex,
        );
      case TypeAlias():
        return _leafApi(
          name: declaration.name.lexeme,
          type: ApiType.typedef,
          docComment: declaration.documentationComment,
          signature: _typedefSignature(declaration),
        );
      case FunctionDeclaration():
        return _leafApi(
          name: declaration.name.lexeme,
          type: ApiType.function,
          docComment: declaration.documentationComment,
          signature: _functionSignature(declaration),
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
    String? signature,
  }) {
    if (name.startsWith('_')) return const [];
    final doc = _docText(docComment);
    if (doc == null) return const [];
    return [
      _ApiInfo(
        name: name,
        type: type,
        docComment: doc,
        members: const [],
        signature: signature,
      ),
    ];
  }

  List<_ApiInfo> _classLikeApi({
    required String name,
    required ApiType type,
    required Comment? docComment,
    required NodeList<ClassMember> members,
    required String bareClassName,
    required Map<String, _ClassIndexEntry> classIndex,
  }) {
    if (name.startsWith('_')) return const [];
    final doc = _docText(docComment);
    if (doc == null) return const [];
    return [
      _ApiInfo(
        name: name,
        type: type,
        docComment: doc,
        members: _extractMembers(members, bareClassName, classIndex),
      ),
    ];
  }

  List<_ApiInfo> _enumApi(
    EnumDeclaration declaration,
    Map<String, _ClassIndexEntry> classIndex,
  ) {
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
    members.addAll(_extractMembers(declaration.body.members, name, classIndex));

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

  List<_MemberInfo> _extractMembers(
    NodeList<ClassMember> members,
    String bareClassName,
    Map<String, _ClassIndexEntry> classIndex,
  ) {
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
              signature: _constructorSignature(member, bareClassName, classIndex),
            ),
          );
        case MethodDeclaration():
          if (member.name.lexeme.startsWith('_')) break;
          final doc = _docText(member.documentationComment);
          if (doc == null) break;
          final isAccessor = member.isGetter || member.isSetter;
          out.add(
            _MemberInfo(
              name: member.name.lexeme,
              category: _methodCategory(member),
              docComment: doc,
              isOverride: _hasOverride(member.metadata),
              readWriteStatus: member.isGetter ? 'no setter' : null,
              signature: isAccessor ? null : _methodSignature(member),
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

  // ── 类索引（跨文件解析 this.x / super.x 参数的真实类型） ───────────────────────

  /// 遍历所有已解析文件的每个类/枚举声明，建立「类名 → 字段类型 / 构造函数参数」索引
  Map<String, _ClassIndexEntry> _buildClassIndex(List<_ParsedFile> parsedFiles) {
    final index = <String, _ClassIndexEntry>{};
    for (final pf in parsedFiles) {
      for (final declaration in pf.unit.declarations) {
        switch (declaration) {
          case ClassDeclaration():
            final name = declaration.namePart.typeName.lexeme;
            index[name] = _classIndexEntry(
              superclassName: declaration.extendsClause?.superclass.name.lexeme,
              members: declaration.body.members,
            );
          case EnumDeclaration():
            final name = declaration.namePart.typeName.lexeme;
            index[name] = _classIndexEntry(
              superclassName: null,
              members: declaration.body.members,
            );
          default:
            break;
        }
      }
    }
    return index;
  }

  _ClassIndexEntry _classIndexEntry({
    required String? superclassName,
    required NodeList<ClassMember> members,
  }) {
    final fieldTypes = <String, String>{};
    final constructors = <String, _CtorIndexInfo>{};
    for (final member in members) {
      switch (member) {
        case FieldDeclaration() when !member.isStatic:
          final typeSource = member.fields.type?.toSource();
          if (typeSource == null) break;
          for (final variable in member.fields.variables) {
            fieldTypes[variable.name.lexeme] = typeSource;
          }
        case ConstructorDeclaration():
          final ctorName = member.name?.lexeme ?? 'new';
          constructors[ctorName] = _ctorIndexInfo(member);
        default:
          break;
      }
    }
    return _ClassIndexEntry(
      superclassName: superclassName,
      fieldTypes: fieldTypes,
      constructors: constructors,
    );
  }

  _CtorIndexInfo _ctorIndexInfo(ConstructorDeclaration ctor) {
    String? superCallCtorName;
    for (final initializer in ctor.initializers) {
      if (initializer is SuperConstructorInvocation) {
        superCallCtorName = initializer.constructorName?.name ?? 'new';
      }
    }
    final params = <String, _ParamRef>{};
    for (final param in ctor.parameters.parameters) {
      final ref = _paramRefFor(param);
      if (ref == null) continue;
      final name = param.name?.lexeme;
      if (name == null) continue;
      params[name] = ref;
    }
    return _CtorIndexInfo(superCallCtorName: superCallCtorName, params: params);
  }

  /// 提取参数的引用类型；带函数类型简写（如 `this.onTap(int x)`）时返回 `null`，标记为不可解析
  _ParamRef? _paramRefFor(FormalParameter param) {
    if (param.functionTypedSuffix != null) return null;
    switch (param) {
      case FieldFormalParameter():
        return const _ParamRef(_ParamRefKind.field);
      case SuperFormalParameter():
        return const _ParamRef(_ParamRefKind.superField);
      case RegularFormalParameter():
        return _ParamRef(_ParamRefKind.regular, param.type?.toSource());
    }
  }

  /// `this.x` 类型解析：只能引用同一个类自己声明的字段
  String? _resolveFieldType(
    String className,
    String fieldName,
    Map<String, _ClassIndexEntry> classIndex,
  ) => classIndex[className]?.fieldTypes[fieldName];

  /// `super.x` 类型解析：沿继承链向上找到实际声明该参数类型的构造函数
  String? _resolveSuperParamType(
    String className,
    String ctorName,
    String paramName,
    Map<String, _ClassIndexEntry> classIndex,
  ) {
    var curClass = className;
    var curCtor = ctorName;
    while (true) {
      final entry = classIndex[curClass];
      final superName = entry?.superclassName;
      if (entry == null || superName == null) return null;
      final ctorInfo = entry.constructors[curCtor];
      final targetCtorName = ctorInfo?.superCallCtorName ?? 'new';
      final superEntry = classIndex[superName];
      final targetCtor = superEntry?.constructors[targetCtorName];
      final ref = targetCtor?.params[paramName];
      if (superEntry == null || ref == null) return null;
      switch (ref.kind) {
        case _ParamRefKind.field:
          return superEntry.fieldTypes[paramName];
        case _ParamRefKind.regular:
          return ref.regularType;
        case _ParamRefKind.superField:
          curClass = superName;
          curCtor = targetCtorName;
      }
    }
  }

  // ── 签名拼接（AST 节点手动拼接 + dart_style 美化） ────────────────────────────

  /// 构造函数签名：不含 `factory` 关键字，不含重定向目标，不含分号；
  /// `this.x`/`super.x` 参数尽可能映射为真实类型，无法解析时保留原写法
  String _constructorSignature(
    ConstructorDeclaration ctor,
    String bareClassName,
    Map<String, _ClassIndexEntry> classIndex,
  ) {
    final ctorName = ctor.name?.lexeme;
    final paramList = _buildParameterListSource(
      ctor.parameters,
      (param) => _renderCtorParam(
        param,
        bareClassName,
        ctorName ?? 'new',
        classIndex,
      ),
    );
    final buf = StringBuffer();
    if (ctor.constKeyword != null) buf.write('const ');
    // 构造函数名不重复类的类型参数（如 `MyBox<T>()` 是非法的，只能写 `MyBox()`）
    buf.write(bareClassName);
    if (ctorName != null) buf.write('.$ctorName');
    buf.write(paramList);
    final raw = buf.toString();
    return _prettifySignature(
      wrapped: 'class $bareClassName {\n  $raw;\n}\n',
      unwrap: _unwrapClassBody,
      fallback: raw,
    );
  }

  /// 渲染单个构造函数参数：`this.x`/`super.x` 解析成功时展开为 `Type name`，否则原样保留
  String _renderCtorParam(
    FormalParameter param,
    String bareClassName,
    String ctorName,
    Map<String, _ClassIndexEntry> classIndex,
  ) {
    final name = param.name?.lexeme;
    String? resolvedType;
    if (name != null && param.functionTypedSuffix == null) {
      switch (param) {
        case FieldFormalParameter():
          resolvedType = _resolveFieldType(bareClassName, name, classIndex);
        case SuperFormalParameter():
          resolvedType = _resolveSuperParamType(
            bareClassName,
            ctorName,
            name,
            classIndex,
          );
        case RegularFormalParameter():
          break;
      }
    }
    if (resolvedType == null) return param.toSource();

    final buf = StringBuffer();
    if (param.isRequiredNamed) buf.write('required ');
    buf.write(resolvedType);
    buf.write(' ');
    buf.write(name);
    final defaultClause = param.defaultClause;
    if (defaultClause != null) {
      buf.write(' ');
      buf.write(defaultClause.separator.lexeme);
      buf.write(' ');
      buf.write(defaultClause.value.toSource());
    }
    return buf.toString();
  }

  /// 方法签名：不含 `static`/`abstract`，操作符保留 `operator` 关键字
  String _methodSignature(MethodDeclaration method) {
    final returnType = method.returnType?.toSource();
    final paramList = method.parameters == null
        ? '()'
        : _buildParameterListSource(
            method.parameters!,
            (param) => param.toSource(),
          );
    final buf = StringBuffer();
    if (returnType != null && returnType.isNotEmpty) {
      buf.write(returnType);
      buf.write(' ');
    }
    if (method.isOperator) buf.write('operator ');
    buf.write(method.name.lexeme);
    buf.write(paramList);
    final raw = buf.toString();
    return _prettifySignature(
      wrapped: 'class _S {\n  external $raw;\n}\n',
      unwrap: (formatted) {
        final body = _unwrapClassBody(formatted);
        return body.startsWith('external ')
            ? body.substring('external '.length)
            : body;
      },
      fallback: raw,
    );
  }

  /// typedef 声明：整节点 toSource() 去掉结尾分号
  String _typedefSignature(TypeAlias typeAlias) {
    final source = typeAlias.toSource();
    final raw = source.endsWith(';')
        ? source.substring(0, source.length - 1)
        : source;
    return _prettifySignature(
      wrapped: '$raw;\n',
      unwrap: _unwrapTrailingSemicolon,
      fallback: raw,
    );
  }

  /// 顶层函数签名：不含函数体
  String _functionSignature(FunctionDeclaration func) {
    final returnType = func.returnType?.toSource();
    final parameters = func.functionExpression.parameters;
    final paramList = parameters == null
        ? '()'
        : _buildParameterListSource(parameters, (param) => param.toSource());
    final buf = StringBuffer();
    if (returnType != null && returnType.isNotEmpty) {
      buf.write(returnType);
      buf.write(' ');
    }
    buf.write(func.name.lexeme);
    buf.write(paramList);
    final raw = buf.toString();
    return _prettifySignature(
      wrapped: 'external $raw;\n',
      unwrap: _unwrapExternalPrefix,
      fallback: raw,
    );
  }

  /// 按 `{}`/`[]` 分组分隔符拼接参数列表源码（构造函数/方法/函数共用）
  String _buildParameterListSource(
    FormalParameterList list,
    String Function(FormalParameter) render,
  ) {
    final buf = StringBuffer('(');
    final delimiter = list.leftDelimiter?.lexeme;
    final closeDelimiter = delimiter == '{'
        ? '}'
        : (delimiter == '[' ? ']' : null);
    var wroteDelimiter = false;
    var first = true;
    for (final param in list.parameters) {
      final entersOptionalGroup =
          !wroteDelimiter &&
          delimiter != null &&
          (param.isNamed || param.isOptionalPositional);
      if (!first) buf.write(', ');
      if (entersOptionalGroup) {
        buf.write(delimiter);
        wroteDelimiter = true;
      }
      buf.write(render(param));
      first = false;
    }
    if (wroteDelimiter && closeDelimiter != null) buf.write(closeDelimiter);
    buf.write(')');
    return buf.toString();
  }

  /// 用 dart_style 格式化 [wrapped]（裸签名包了一层占位容器），再用 [unwrap] 拆出签名本体；
  /// 格式化失败（如遇到本实现未覆盖的语法形状）时返回 [fallback] 单行裸签名
  String _prettifySignature({
    required String wrapped,
    required String Function(String) unwrap,
    required String fallback,
  }) {
    try {
      final formatted = _formatter.format(wrapped);
      return unwrap(formatted);
    } catch (_) {
      return fallback;
    }
  }

  /// 拆出 `class X {\n  ...\n}\n` 包裹后的 body，去掉每行 2 空格缩进与结尾分号
  String _unwrapClassBody(String formatted) {
    final lines = formatted.split('\n');
    final bodyLines = lines.sublist(1, lines.length - 2);
    final unindented = bodyLines
        .map((l) => l.startsWith('  ') ? l.substring(2) : l)
        .join('\n');
    return unindented.endsWith(';')
        ? unindented.substring(0, unindented.length - 1)
        : unindented;
  }

  /// 去掉格式化结果结尾的分号
  String _unwrapTrailingSemicolon(String formatted) {
    final trimmed = formatted.trimRight();
    return trimmed.endsWith(';')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  /// 去掉格式化结果开头的 `external ` 前缀与结尾的分号
  String _unwrapExternalPrefix(String formatted) {
    final withoutSemicolon = _unwrapTrailingSemicolon(formatted);
    return withoutSemicolon.startsWith('external ')
        ? withoutSemicolon.substring('external '.length)
        : withoutSemicolon;
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
    if (api.signature != null) {
      buf.writeln('```dart');
      buf.writeln(api.signature);
      buf.writeln('```');
      buf.writeln();
    }
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
        if (m.signature != null) {
          buf.writeln();
          buf.writeln('```dart');
          buf.writeln(m.signature);
          buf.writeln('```');
          buf.writeln();
        }
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
  final String? signature;
  const _ApiInfo({
    required this.name,
    required this.type,
    required this.docComment,
    required this.members,
    this.signature,
  });
}

class _MemberInfo {
  final String name;
  final MemberCategory category;
  final String docComment;
  final bool isOverride;
  final String? readWriteStatus;
  final String? signature;

  const _MemberInfo({
    required this.name,
    required this.category,
    required this.docComment,
    required this.isOverride,
    this.readWriteStatus,
    this.signature,
  });

  _MemberInfo withReadWrite(String status) => _MemberInfo(
    name: name,
    category: category,
    docComment: docComment,
    isOverride: isOverride,
    readWriteStatus: status,
    signature: signature,
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

/// 单个文件解析结果，供两阶段扫描传递
class _ParsedFile {
  final String sourcePath;
  final CompilationUnit unit;
  const _ParsedFile(this.sourcePath, this.unit);
}

/// 类索引条目：父类名 + 字段类型表 + 构造函数参数表
class _ClassIndexEntry {
  final String? superclassName;
  final Map<String, String> fieldTypes;
  final Map<String, _CtorIndexInfo> constructors;
  const _ClassIndexEntry({
    required this.superclassName,
    required this.fieldTypes,
    required this.constructors,
  });
}

/// 单个构造函数的索引信息：实际调用的父类构造函数名 + 各参数的引用类型
class _CtorIndexInfo {
  final String? superCallCtorName;
  final Map<String, _ParamRef> params;
  const _CtorIndexInfo({required this.superCallCtorName, required this.params});
}

enum _ParamRefKind { field, superField, regular }

/// 构造函数参数的引用类型：`this.x`/`super.x`/显式类型
class _ParamRef {
  final _ParamRefKind kind;
  final String? regularType;
  const _ParamRef(this.kind, [this.regularType]);
}
