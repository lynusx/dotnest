import 'dart:io';
import 'package:path/path.dart' as p;
import '../model/link_rewrite_result.dart';

/// 单文件重写结果：新内容 + 替换次数
class RewriteOutcome {
  final String content;
  final int replacementCount;

  const RewriteOutcome(this.content, this.replacementCount);
}

enum _LineZone { frontMatter, fence, normal }

/// 保留原始换行符的单行数据
class _Line {
  final String text;
  final String terminator;

  _Line(this.text, this.terminator);
}

/// 扫描目标目录并按规则重写 Markdown 中的 [] 引用为链接
class LinkRewriteService {
  /// 递归扫描 [targetDir] 下所有 .md/.markdown 文件（大小写不敏感后缀匹配）
  Future<List<File>> collectMarkdownFiles(String targetDir) async {
    final dir = Directory(targetDir);
    final files = <File>[];
    if (!await dir.exists()) return files;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).toLowerCase();
      if (ext == '.md' || ext == '.markdown') {
        files.add(entity);
      }
    }
    return files;
  }

  /// 批量处理：扫描 + 逐文件重写 + 按 [mode] 写出，返回每文件结果。
  /// 单个文件失败不影响其余文件的处理。
  Future<List<LinkRewriteFileResult>> processDirectory({
    required String targetDir,
    required Map<String, String> urlMap,
    required RewriteOutputMode mode,
    String? outputDir,
  }) async {
    final files = await collectMarkdownFiles(targetDir);
    final results = <LinkRewriteFileResult>[];

    for (final file in files) {
      final relativePath = p.relative(file.path, from: targetDir);
      try {
        final content = await file.readAsString();
        final outcome = rewriteContent(content, urlMap);

        if (mode == RewriteOutputMode.overwrite) {
          await file.writeAsString(outcome.content);
        } else {
          final outPath = p.join(outputDir!, relativePath);
          await Directory(p.dirname(outPath)).create(recursive: true);
          await File(outPath).writeAsString(outcome.content);
        }

        results.add(
          LinkRewriteFileResult(
            relativePath: relativePath,
            replacementCount: outcome.replacementCount,
            success: true,
          ),
        );
      } catch (e) {
        results.add(
          LinkRewriteFileResult(
            relativePath: relativePath,
            replacementCount: 0,
            success: false,
            error: e.toString(),
          ),
        );
      }
    }

    return results;
  }

  /// 核心重写算法：纯文本处理，不依赖 IO，可直接单元测试。
  ///
  /// 保护区域（YAML Front Matter / 代码块 / 行内代码）内的 [] 不会被扫描或修改，
  /// 原始换行符（\n 或 \r\n）逐行保留，不做归一化。
  RewriteOutcome rewriteContent(String content, Map<String, String> urlMap) {
    final lines = _splitLines(content);
    final zones = _classifyZones(lines);
    final headingTexts = _extractHeadings(lines, zones);

    var totalCount = 0;
    final buffer = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (zones[i] == _LineZone.normal) {
        final (newText, count) = _rewriteLine(line.text, urlMap, headingTexts);
        totalCount += count;
        buffer.write(newText);
      } else {
        buffer.write(line.text);
      }
      buffer.write(line.terminator);
    }

    return RewriteOutcome(buffer.toString(), totalCount);
  }

  // ── 按行切分，保留每行原始换行符 ─────────────────────────────────────────────

  List<_Line> _splitLines(String content) {
    final lines = <_Line>[];
    var start = 0;
    for (var i = 0; i < content.length; i++) {
      if (content[i] == '\n') {
        final hasCR = i > start && content[i - 1] == '\r';
        final textEnd = hasCR ? i - 1 : i;
        lines.add(
          _Line(content.substring(start, textEnd), hasCR ? '\r\n' : '\n'),
        );
        start = i + 1;
      }
    }
    if (start < content.length) {
      lines.add(_Line(content.substring(start), ''));
    }
    return lines;
  }

  // ── 区域分类：YAML Front Matter / 代码块 / 正文 ──────────────────────────────

  static final _openFencePattern = RegExp(r'^ {0,3}(`{3,}|~{3,})');

  List<_LineZone> _classifyZones(List<_Line> lines) {
    final zones = List<_LineZone>.filled(lines.length, _LineZone.normal);
    var startIdx = 0;

    // Front Matter：仅当第一行严格等于 '---' 时才可能存在
    if (lines.isNotEmpty && lines[0].text == '---') {
      var closeIdx = -1;
      for (var i = 1; i < lines.length; i++) {
        if (lines[i].text == '---') {
          closeIdx = i;
          break;
        }
      }
      if (closeIdx != -1) {
        for (var i = 0; i <= closeIdx; i++) {
          zones[i] = _LineZone.frontMatter;
        }
        startIdx = closeIdx + 1;
      }
    }

    // Fenced code block
    var inFence = false;
    var fenceChar = '';
    var fenceLen = 0;
    for (var i = startIdx; i < lines.length; i++) {
      final text = lines[i].text;
      if (!inFence) {
        final m = _openFencePattern.firstMatch(text);
        if (m != null) {
          zones[i] = _LineZone.fence;
          inFence = true;
          final fenceStr = m.group(1)!;
          fenceChar = fenceStr[0];
          fenceLen = fenceStr.length;
        }
        continue;
      }
      zones[i] = _LineZone.fence;
      final trimmed = text.trim();
      final closePattern = RegExp('^$fenceChar{$fenceLen,}\$');
      if (closePattern.hasMatch(trimmed)) {
        inFence = false;
      }
    }

    return zones;
  }

  // ── 提取正文区域内的 H3 标题原文（锚点直接取标题原文，不做 slug 化） ──────────

  static final _headingPattern = RegExp(r'^###(?!#)[ \t]+(.+?)\s*$');

  Set<String> _extractHeadings(List<_Line> lines, List<_LineZone> zones) {
    final headings = <String>{};
    for (var i = 0; i < lines.length; i++) {
      if (zones[i] != _LineZone.normal) continue;
      final m = _headingPattern.firstMatch(lines[i].text);
      if (m != null) headings.add(m.group(1)!);
    }
    return headings;
  }

  // ── 单行重写：跳过行内代码 span，线性扫描处理已有链接 / 裸方括号 ──────────────

  List<(int, int)> _codeSpans(String line) {
    final spans = <(int, int)>[];
    var i = 0;
    while (i < line.length) {
      if (line[i] == '`') {
        final close = line.indexOf('`', i + 1);
        if (close == -1) break;
        spans.add((i, close));
        i = close + 1;
      } else {
        i++;
      }
    }
    return spans;
  }

  ({String base, String? anchor}) _splitBase(String label) {
    final dot = label.indexOf('.');
    if (dot == -1) return (base: label, anchor: null);
    return (base: label.substring(0, dot), anchor: label.substring(dot + 1));
  }

  (String, int) _rewriteLine(
    String line,
    Map<String, String> urlMap,
    Set<String> headingTexts,
  ) {
    final spanStarts = <int, int>{
      for (final s in _codeSpans(line)) s.$1: s.$2,
    };

    final buffer = StringBuffer();
    var count = 0;
    var pos = 0;

    while (pos < line.length) {
      final spanEnd = spanStarts[pos];
      if (spanEnd != null) {
        buffer.write(line.substring(pos, spanEnd + 1));
        pos = spanEnd + 1;
        continue;
      }

      final ch = line[pos];
      if (ch != '[') {
        buffer.write(ch);
        pos++;
        continue;
      }

      final closeBracket = line.indexOf(']', pos + 1);
      if (closeBracket == -1) {
        buffer.write(ch);
        pos++;
        continue;
      }

      final label = line.substring(pos + 1, closeBracket);

      // 已有链接 [label](href)：仅当 base 命中 urlMap 时更新 href，否则原样保留
      if (closeBracket + 1 < line.length && line[closeBracket + 1] == '(') {
        final closeParen = line.indexOf(')', closeBracket + 2);
        if (closeParen != -1) {
          final href = line.substring(closeBracket + 2, closeParen);
          final split = _splitBase(label);
          final mapped = urlMap[split.base];
          if (mapped != null) {
            final newHref = split.anchor == null
                ? mapped
                : '$mapped#${split.anchor}';
            buffer.write('[$label]($newHref)');
            if (newHref != href) count++;
          } else {
            buffer.write(line.substring(pos, closeParen + 1));
          }
          pos = closeParen + 1;
          continue;
        }
      }

      // 裸方括号 [label]：规则1 → 规则2 → 规则3
      final split = _splitBase(label);
      final mapped = urlMap[split.base];
      if (mapped != null) {
        final newHref = split.anchor == null
            ? mapped
            : '$mapped#${split.anchor}';
        buffer.write('[$label]($newHref)');
        count++;
      } else if (headingTexts.contains(label)) {
        buffer.write('[$label](#$label)');
        count++;
      } else {
        buffer.write('[$label]');
      }
      pos = closeBracket + 1;
    }

    return (buffer.toString(), count);
  }
}
