import 'package:dotnest/features/yuque/model/md_file_item.dart';
import 'package:dotnest/features/yuque/model/scan_group_node.dart';
import 'package:flutter_test/flutter_test.dart';

/// 与 YuqueViewModel.exportGroupedMarkdown 保持一致的导出逻辑，用于验证输出格式
String _exportMarkdown(List<MdFileItem> files, String rootPath) {
  final tree = ScanGroupNode.buildTree(files, rootPath);
  final buffer = StringBuffer();

  void writeGroup(ScanGroupNode node, int depth) {
    final indent = '  ' * depth;
    buffer.writeln('$indent- [${node.name}]()');
    for (final file in node.files) {
      buffer.writeln('$indent  - [${file.title}](${file.slug})');
    }
    for (final child in node.children) {
      writeGroup(child, depth + 1);
    }
  }

  for (final file in tree.rootFiles) {
    buffer.writeln('- [${file.title}](${file.slug})');
  }
  for (final group in tree.groups) {
    writeGroup(group, 0);
  }
  return buffer.toString();
}

MdFileItem _item(String relativePath, String title, String slug) => MdFileItem(
  filePath: '/root/$relativePath',
  fileName: title,
  slug: slug,
  title: title,
  body: '',
);

void main() {
  test('导出结构化目录 .md，按源目录分组并跳过根目录', () {
    final files = [
      _item('animation/Animation.md', 'Animation', 'Animation-class'),
      _item(
        'animation/AnimationStatus.md',
        'AnimationStatus',
        'AnimationStatus-enum',
      ),
      _item(
        'animation/AnimationStatusListener.md',
        'AnimationStatusListener',
        'AnimationStatusListener-typedef',
      ),
      _item(
        'animation_controller/AnimationBehavior.md',
        'AnimationBehavior',
        'AnimationBehavior-enum',
      ),
      _item(
        'animation_controller/AnimationController.md',
        'AnimationController',
        'AnimationController-class',
      ),
    ];

    final markdown = _exportMarkdown(files, '/root');

    expect(markdown, '''
- [animation]()
  - [Animation](Animation-class)
  - [AnimationStatus](AnimationStatus-enum)
  - [AnimationStatusListener](AnimationStatusListener-typedef)
- [animation_controller]()
  - [AnimationBehavior](AnimationBehavior-enum)
  - [AnimationController](AnimationController-class)
''');
  });

  test('根目录下的文件直接列出，不计入任何分组', () {
    final files = [
      _item('Readme.md', 'Readme', 'Readme'),
      _item('animation/Animation.md', 'Animation', 'Animation-class'),
    ];

    final markdown = _exportMarkdown(files, '/root');

    expect(markdown, '''
- [Readme](Readme)
- [animation]()
  - [Animation](Animation-class)
''');
  });
}
