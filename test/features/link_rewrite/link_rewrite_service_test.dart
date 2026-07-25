import 'package:dotnest/features/link_rewrite/service/link_rewrite_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = LinkRewriteService();

  test('规则1：无 anchor 命中 url_map', () {
    final outcome = service.rewriteContent(
      '[Scaffold] widget.',
      {'Scaffold': 'https://www.yuque.com/flutter/Scaffold'},
    );
    expect(
      outcome.content,
      '[Scaffold](https://www.yuque.com/flutter/Scaffold) widget.',
    );
    expect(outcome.replacementCount, 1);
  });

  test('规则1：带 anchor（按第一个点拆分 base/anchor）', () {
    final outcome = service.rewriteContent(
      'See [Scaffold.of] for details.',
      {'Scaffold': 'https://www.yuque.com/flutter/Scaffold'},
    );
    expect(
      outcome.content,
      'See [Scaffold.of](https://www.yuque.com/flutter/Scaffold#of) for details.',
    );
    expect(outcome.replacementCount, 1);
  });

  test('规则1：更新已有链接的 href，标签文字不变', () {
    final outcome = service.rewriteContent(
      '[Scaffold.of](https://old-url.example.com)',
      {'Scaffold': 'https://www.yuque.com/flutter/Scaffold'},
    );
    expect(
      outcome.content,
      '[Scaffold.of](https://www.yuque.com/flutter/Scaffold#of)',
    );
    expect(outcome.replacementCount, 1);
  });

  test('已有链接 base 未命中 map，即使存在同名 H3 也保持完全不变', () {
    const content = '''
### Unknown.foo

[Unknown.foo](https://old-url.example.com)
''';
    final outcome = service.rewriteContent(content, {'Other': 'https://x'});
    expect(outcome.content, content);
    expect(outcome.replacementCount, 0);
  });

  test('规则2：H3 标题原文直接作为锚点，不做 slug 化', () {
    const content = '''
### My Method

See [My Method] for usage.
''';
    final outcome = service.rewriteContent(content, {});
    expect(
      outcome.content,
      '''
### My Method

See [My Method](#My Method) for usage.
''',
    );
    expect(outcome.replacementCount, 1);
  });

  test('规则2未命中：保持原样', () {
    const content = '[NoSuchHeading] text.';
    final outcome = service.rewriteContent(content, {});
    expect(outcome.content, content);
    expect(outcome.replacementCount, 0);
  });

  test('规则3兜底：无 map 命中也无 H3 命中', () {
    const content = '[Foo] plain text.';
    final outcome = service.rewriteContent(content, {'Bar': 'https://x'});
    expect(outcome.content, content);
    expect(outcome.replacementCount, 0);
  });

  test('Front Matter 内容保护，仅正文被替换', () {
    const content = '''
---
title: [Foo]
---
[Foo] body text.
''';
    final outcome = service.rewriteContent(content, {'Foo': 'https://x'});
    expect(
      outcome.content,
      '''
---
title: [Foo]
---
[Foo](https://x) body text.
''',
    );
    expect(outcome.replacementCount, 1);
  });

  test('三反引号代码块内容保护', () {
    const content = '''
```
[Foo]
```
[Foo] outside.
''';
    final outcome = service.rewriteContent(content, {'Foo': 'https://x'});
    expect(
      outcome.content,
      '''
```
[Foo]
```
[Foo](https://x) outside.
''',
    );
    expect(outcome.replacementCount, 1);
  });

  test('波浪线代码块内容保护', () {
    const content = '''
~~~
[Foo]
~~~
[Foo] outside.
''';
    final outcome = service.rewriteContent(content, {'Foo': 'https://x'});
    expect(
      outcome.content,
      '''
~~~
[Foo]
~~~
[Foo](https://x) outside.
''',
    );
    expect(outcome.replacementCount, 1);
  });

  test('单反引号行内代码保护', () {
    const content = '`[Foo]` and [Foo] outside.';
    final outcome = service.rewriteContent(content, {'Foo': 'https://x'});
    expect(outcome.content, '`[Foo]` and [Foo](https://x) outside.');
    expect(outcome.replacementCount, 1);
  });

  test('大小写严格敏感：map key 与 H3 标题均区分大小写', () {
    const content = '''
### Foo

[scaffold] and [foo].
''';
    final outcome = service.rewriteContent(content, {
      'Scaffold': 'https://x',
    });
    expect(outcome.content, content);
    expect(outcome.replacementCount, 0);
  });

  test('规则1优先于规则2：同名同时命中 JSON 与 H3 时取 JSON', () {
    const content = '''
### Scaffold

[Scaffold] text.
''';
    final outcome = service.rewriteContent(content, {
      'Scaffold': 'https://www.yuque.com/flutter/Scaffold',
    });
    expect(
      outcome.content,
      '''
### Scaffold

[Scaffold](https://www.yuque.com/flutter/Scaffold) text.
''',
    );
    expect(outcome.replacementCount, 1);
  });

  test('CRLF 换行符保留，不被归一化为 LF', () {
    const content =
        '---\r\ntitle: x\r\n---\r\n[Foo] line one.\r\n[Bar] line two.\r\n';
    final outcome = service.rewriteContent(content, {'Foo': 'https://x'});
    expect(
      outcome.content,
      '---\r\ntitle: x\r\n---\r\n[Foo](https://x) line one.\r\n[Bar] line two.\r\n',
    );
    expect(outcome.replacementCount, 1);
    expect(outcome.content.contains('\n\n'), isFalse);
  });
}
