import 'dart:convert';

import 'package:dotnest/features/yuque/model/md_file_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// 与 YuqueViewModel.exportLinksJson 保持一致的导出逻辑，用于验证输出格式
String _exportLinksJson(List<MdFileItem> files, String baseUrl) {
  final normalizedBase = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  final links = <String, String>{
    for (final file in files)
      if (file.hasLinkFields) file.title: '$normalizedBase/${file.slug}',
  };
  return const JsonEncoder.withIndent('  ').convert(links);
}

MdFileItem _item(String title, String slug, {bool hasLinkFields = true}) =>
    MdFileItem(
      filePath: '/root/$title.md',
      fileName: title,
      slug: slug,
      title: title,
      body: '',
      hasLinkFields: hasLinkFields,
    );

void main() {
  test('导出 {title: baseUrl/slug} 结构的链接 json', () {
    final files = [
      _item('Animation', 'Animation-class'),
      _item('AnimationStatus', 'AnimationStatus-enum'),
      _item('AnimationStatusListener', 'AnimationStatusListener-typedef'),
      _item('AnimationBehavior', 'AnimationBehavior-enum'),
      _item('AnimationController', 'AnimationController-class'),
    ];

    final result = jsonDecode(_exportLinksJson(files, 'https://www.yuque.com'));

    expect(result, {
      'Animation': 'https://www.yuque.com/Animation-class',
      'AnimationStatus': 'https://www.yuque.com/AnimationStatus-enum',
      'AnimationStatusListener':
          'https://www.yuque.com/AnimationStatusListener-typedef',
      'AnimationBehavior': 'https://www.yuque.com/AnimationBehavior-enum',
      'AnimationController': 'https://www.yuque.com/AnimationController-class',
    });
  });

  test('baseURL 末尾多余的 / 会被去除，避免拼接出双斜杠', () {
    final files = [_item('Animation', 'Animation-class')];

    final result = jsonDecode(
      _exportLinksJson(files, 'https://www.yuque.com/'),
    );

    expect(result, {'Animation': 'https://www.yuque.com/Animation-class'});
  });

  test('无 Front Matter 或缺少 title/slug 字段的文件会被跳过', () {
    final files = [
      _item('Animation', 'Animation-class'),
      _item('NoFrontMatter', 'NoFrontMatter', hasLinkFields: false),
    ];

    final result = jsonDecode(
      _exportLinksJson(files, 'https://www.yuque.com'),
    );

    expect(result, {'Animation': 'https://www.yuque.com/Animation-class'});
  });
}
