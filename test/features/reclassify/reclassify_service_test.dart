import 'dart:io';

import 'package:dotnest/features/reclassify/model/reclassify_result.dart';
import 'package:dotnest/features/reclassify/service/reclassify_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final service = ReclassifyService();
  late Directory sourceDir;

  setUp(() {
    sourceDir = Directory.systemTemp.createTempSync('dotnest_reclassify_');
  });

  tearDown(() {
    sourceDir.deleteSync(recursive: true);
  });

  void writeMd(String relativePath, String title) {
    final file = File(p.join(sourceDir.path, relativePath));
    file.createSync(recursive: true);
    file.writeAsStringSync('''
---
title: $title
---
Body of $title.
''');
  }

  const yamlConfig = '''
Future与异步计算:
  核心类型与工具:
    - Future
    - Completer
定时器:
  计时器类与处理器:
    - Timer
''';

  test('findConfigCandidates：唯一匹配 *_api_list.yaml', () {
    File(
      p.join(sourceDir.path, 'dart_async_api_list.yaml'),
    ).writeAsStringSync(yamlConfig);
    File(p.join(sourceDir.path, 'other.yaml')).writeAsStringSync('a: 1');

    final candidates = service.findConfigCandidates(sourceDir.path);
    expect(candidates, hasLength(1));
    expect(p.basename(candidates.first.path), 'dart_async_api_list.yaml');
  });

  test('findConfigCandidates：多个匹配返回全部候选', () {
    File(
      p.join(sourceDir.path, 'a_api_list.yaml'),
    ).writeAsStringSync(yamlConfig);
    File(
      p.join(sourceDir.path, 'b_api_list.yaml'),
    ).writeAsStringSync(yamlConfig);

    final candidates = service.findConfigCandidates(sourceDir.path);
    expect(candidates, hasLength(2));
  });

  test('parseConfig：多层级嵌套解析为 叶子->路径段 映射', () {
    final map = service.parseConfig(yamlConfig);
    expect(map['Future'], ['Future与异步计算', '核心类型与工具']);
    expect(map['Completer'], ['Future与异步计算', '核心类型与工具']);
    expect(map['Timer'], ['定时器', '计时器类与处理器']);
  });

  test('parseConfig：根节点非映射时抛出 FormatException', () {
    expect(() => service.parseConfig('- a\n- b'), throwsFormatException);
  });

  test('reclassify：完整流程 —— 拍平、建目录、按 title 匹配移动', () async {
    writeMd('a/Future.md', 'Future');
    writeMd('a/b/Completer.md', 'Completer');
    writeMd('Timer.md', 'Timer');

    final configFile = File(p.join(sourceDir.path, 'x_api_list.yaml'))
      ..writeAsStringSync(yamlConfig);

    final outcome = await service.reclassify(
      sourceDir: sourceDir.path,
      configPath: configFile.path,
    );

    expect(outcome.stats.totalFiles, 3);
    expect(outcome.stats.movedFiles, 3);
    expect(outcome.stats.missingTitleFiles, 0);
    expect(outcome.stats.unmatchedFiles, 0);
    expect(outcome.warnings, isEmpty);

    expect(
      File(
        p.join(
          sourceDir.path,
          'Future与异步计算',
          '核心类型与工具',
          'Future.md',
        ),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        p.join(
          sourceDir.path,
          'Future与异步计算',
          '核心类型与工具',
          'Completer.md',
        ),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        p.join(sourceDir.path, '定时器', '计时器类与处理器', 'Timer.md'),
      ).existsSync(),
      isTrue,
    );

    // 原始位置应已被拍平移走
    expect(File(p.join(sourceDir.path, 'a', 'Future.md')).existsSync(), isFalse);
  });

  test('reclassify：缺少 title 字段的文件跳过并保留在根目录', () async {
    final noTitleFile = File(p.join(sourceDir.path, 'no_title.md'))
      ..writeAsStringSync('Just plain body without front matter.');
    final configFile = File(p.join(sourceDir.path, 'x_api_list.yaml'))
      ..writeAsStringSync(yamlConfig);

    final outcome = await service.reclassify(
      sourceDir: sourceDir.path,
      configPath: configFile.path,
    );

    expect(outcome.stats.missingTitleFiles, 1);
    expect(outcome.warnings, hasLength(1));
    expect(outcome.warnings.first.type, ReclassifyWarningType.missingTitle);
    expect(noTitleFile.existsSync(), isTrue);
  });

  test('reclassify：title 未匹配任何叶子节点时跳过并保留在根目录', () async {
    writeMd('unknown.md', 'NoSuchLeaf');
    final configFile = File(p.join(sourceDir.path, 'x_api_list.yaml'))
      ..writeAsStringSync(yamlConfig);

    final outcome = await service.reclassify(
      sourceDir: sourceDir.path,
      configPath: configFile.path,
    );

    expect(outcome.stats.unmatchedFiles, 1);
    expect(outcome.warnings.first.type, ReclassifyWarningType.unmatchedTitle);
    expect(File(p.join(sourceDir.path, 'unknown.md')).existsSync(), isTrue);
  });

  test('reclassify：title 大小写不一致视为未匹配', () async {
    writeMd('future_lower.md', 'future');
    final configFile = File(p.join(sourceDir.path, 'x_api_list.yaml'))
      ..writeAsStringSync(yamlConfig);

    final outcome = await service.reclassify(
      sourceDir: sourceDir.path,
      configPath: configFile.path,
    );

    expect(outcome.stats.unmatchedFiles, 1);
    expect(outcome.stats.movedFiles, 0);
  });

  test('reclassify：拍平阶段同名文件冲突时自动重命名，各自仍按 title 正确归类', () async {
    // 两个不同子目录下的同名文件 dup.md，拍平到根目录时会产生命名冲突
    writeMd('a/dup.md', 'Future');
    writeMd('b/dup.md', 'Timer');
    final configFile = File(p.join(sourceDir.path, 'x_api_list.yaml'))
      ..writeAsStringSync(yamlConfig);

    final outcome = await service.reclassify(
      sourceDir: sourceDir.path,
      configPath: configFile.path,
    );

    expect(outcome.stats.totalFiles, 2);
    expect(outcome.stats.movedFiles, 2);
    expect(outcome.warnings, isEmpty);

    // 二者拍平后重命名为不同文件名，分别正确移动到各自分类目录，无内容丢失
    final futureDir = Directory(
      p.join(sourceDir.path, 'Future与异步计算', '核心类型与工具'),
    );
    final timerDir = Directory(p.join(sourceDir.path, '定时器', '计时器类与处理器'));
    final futureFiles = futureDir.listSync().whereType<File>().toList();
    final timerFiles = timerDir.listSync().whereType<File>().toList();

    expect(futureFiles, hasLength(1));
    expect(timerFiles, hasLength(1));
    expect(futureFiles.first.readAsStringSync(), contains('title: Future'));
    expect(timerFiles.first.readAsStringSync(), contains('title: Timer'));
  });

  test('reclassify：拍平后清理被搬空的原始子目录，非空目录保持不变', () async {
    writeMd('a/b/Future.md', 'Future');
    // a/c 下保留一个非 .md 文件，拍平后该目录不应被删除
    File(p.join(sourceDir.path, 'a', 'c', 'keep.txt'))
      ..createSync(recursive: true)
      ..writeAsStringSync('keep me');
    final configFile = File(p.join(sourceDir.path, 'x_api_list.yaml'))
      ..writeAsStringSync(yamlConfig);

    await service.reclassify(sourceDir: sourceDir.path, configPath: configFile.path);

    // a/b 被搬空后应连同其父目录 a 一并删除（a 下已无其他内容吗？不，a/c 仍存在，故只删 a/b）
    expect(Directory(p.join(sourceDir.path, 'a', 'b')).existsSync(), isFalse);
    expect(Directory(p.join(sourceDir.path, 'a')).existsSync(), isTrue);
    expect(Directory(p.join(sourceDir.path, 'a', 'c')).existsSync(), isTrue);
    expect(File(p.join(sourceDir.path, 'a', 'c', 'keep.txt')).existsSync(), isTrue);
  });

  test('collectMarkdownFiles：递归收集所有子目录下的 .md 文件', () async {
    writeMd('x/y/z.md', 'Z');
    writeMd('w.md', 'W');
    File(p.join(sourceDir.path, 'ignore.txt')).writeAsStringSync('not md');

    final files = await service.collectMarkdownFiles(sourceDir.path);
    expect(files, hasLength(2));
  });
}
