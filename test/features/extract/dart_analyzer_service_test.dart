import 'dart:io';

import 'package:dotnest/features/extract/model/extract_result.dart';
import 'package:dotnest/features/extract/service/dart_analyzer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final service = DartAnalyzerService();
  late Directory sourceDir;
  late Directory outputDir;

  setUp(() {
    sourceDir = Directory.systemTemp.createTempSync('dotnest_extract_src_');
    outputDir = Directory.systemTemp.createTempSync('dotnest_extract_out_');
  });

  tearDown(() {
    sourceDir.deleteSync(recursive: true);
    outputDir.deleteSync(recursive: true);
  });

  test('仅含 library 文档注释、无公开声明的文件，直接展开生成同名 .md，不归档到同名子目录', () async {
    File(
      p.join(sourceDir.path, 'foo.dart'),
    ).writeAsStringSync('''
/// Foo 库的说明文档。
library;

int _privateHelper() => 1;
''');

    final results = await service.extractFromDirectory(
      sourceDir.path,
      outputDir.path,
    );

    expect(results, hasLength(1));
    expect(results.first.success, isTrue);
    expect(results.first.apiType, ApiType.library);

    final expandedFile = File(p.join(outputDir.path, 'foo.md'));
    final nestedFile = File(p.join(outputDir.path, 'foo', 'foo.md'));
    expect(expandedFile.existsSync(), isTrue);
    expect(nestedFile.existsSync(), isFalse);
    expect(expandedFile.readAsStringSync(), contains('Foo 库的说明文档。'));
  });

  test('含公开声明的文件，仍归档到同名子目录下', () async {
    File(
      p.join(sourceDir.path, 'bar.dart'),
    ).writeAsStringSync('''
/// Bar 类。
class Bar {}
''');

    final results = await service.extractFromDirectory(
      sourceDir.path,
      outputDir.path,
    );

    expect(results, hasLength(1));
    expect(results.first.apiType, ApiType.classType);

    final nestedFile = File(p.join(outputDir.path, 'bar', 'Bar.md'));
    expect(nestedFile.existsSync(), isTrue);
  });

  test('嵌套目录下仅含 library 文档的文件，展开到对应相对目录而非其子目录', () async {
    final nestedSourceDir = Directory(p.join(sourceDir.path, 'nested'))
      ..createSync(recursive: true);
    File(
      p.join(nestedSourceDir.path, 'baz.dart'),
    ).writeAsStringSync('''
/// Baz 库的说明文档。
library;
''');

    await service.extractFromDirectory(sourceDir.path, outputDir.path);

    final expandedFile = File(p.join(outputDir.path, 'nested', 'baz.md'));
    final nestedFile = File(
      p.join(outputDir.path, 'nested', 'baz', 'baz.md'),
    );
    expect(expandedFile.existsSync(), isTrue);
    expect(nestedFile.existsSync(), isFalse);
  });

  test('生成的 markdown 文件名与 frontmatter 中的 title 保持一致', () async {
    File(
      p.join(sourceDir.path, 'qux.dart'),
    ).writeAsStringSync('''
/// Qux 类。
class Qux {}
''');

    final results = await service.extractFromDirectory(
      sourceDir.path,
      outputDir.path,
    );

    final fileName = results.first.fileName;
    final title = fileName.substring(0, fileName.length - '.md'.length);
    final content = File(
      p.join(outputDir.path, 'qux', fileName),
    ).readAsStringSync();
    expect(content, contains('title: $title'));
    expect(content, contains('slug: $title-class'));
  });

  test('library 文档的 title 与文件名一致，slug 为 title-library', () async {
    File(
      p.join(sourceDir.path, 'quux.dart'),
    ).writeAsStringSync('''
/// Quux 库的说明文档。
library;
''');

    await service.extractFromDirectory(sourceDir.path, outputDir.path);

    final content = File(
      p.join(outputDir.path, 'quux.md'),
    ).readAsStringSync();
    expect(content, contains('title: quux'));
    expect(content, contains('slug: quux-library'));
  });

  test('过滤文档注释中的 @docImport 声明行，不输出到生成的 markdown', () async {
    File(
      p.join(sourceDir.path, 'corge.dart'),
    ).writeAsStringSync('''
/// @docImport 'src/painting/box_decoration.dart';
/// @docImport 'dart:ui';
library;

/// A decoration for a box.
///
/// See also the docs.
class Corge {
  /// Creates a decoration.
  const Corge();
}
''');

    await service.extractFromDirectory(sourceDir.path, outputDir.path);

    final content = File(
      p.join(outputDir.path, 'corge', 'Corge.md'),
    ).readAsStringSync();
    expect(content, isNot(contains('@docImport')));
    expect(content, isNot(contains('box_decoration.dart')));
    expect(content, contains('A decoration for a box.'));
  });
}
