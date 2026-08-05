import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../model/reclassify_result.dart';

/// 扫描目标目录、解析分类配置并按规则重新分组 .md 文件
class ReclassifyService {
  /// 在 [sourceDir] 根目录（非递归）下查找文件名以 `_api_list.yaml` 结尾的配置文件
  List<File> findConfigCandidates(String sourceDir) {
    final dir = Directory(sourceDir);
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).endsWith('_api_list.yaml'))
        .toList();
  }

  /// 递归收集 [sourceDir] 下所有 .md 文件（大小写不敏感后缀匹配）
  Future<List<File>> collectMarkdownFiles(String sourceDir) async {
    final dir = Directory(sourceDir);
    final files = <File>[];
    if (!await dir.exists()) return files;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() == '.md') {
        files.add(entity);
      }
    }
    return files;
  }

  /// 将 YAML 配置解析为 `叶子节点名称 -> 目录路径段列表` 的映射。
  /// 支持任意层级嵌套，叶子节点必须是字符串列表。
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
        } else {
          throw FormatException('分类节点 "$key" 的取值格式无效');
        }
      }
    }

    walk(doc, []);
    return result;
  }

  /// 执行完整调整分类流程：拍平收集 → 创建新目录结构 → 按 title 匹配移动。
  Future<ReclassifyOutcome> reclassify({
    required String sourceDir,
    required String configPath,
  }) async {
    final yamlContent = await File(configPath).readAsString();
    final leafMap = parseConfig(yamlContent);

    final mdFiles = await collectMarkdownFiles(sourceDir);

    // Step 1：拍平收集 —— 将所有 .md 文件移动到 sourceDir 根目录
    final flattenedPaths = <String>[];
    final vacatedDirs = <String>{};
    for (final file in mdFiles) {
      final originalDir = p.dirname(file.path);
      if (p.equals(originalDir, sourceDir)) {
        flattenedPaths.add(file.path);
        continue;
      }
      final target = _resolveCollisionPath(
        p.join(sourceDir, p.basename(file.path)),
      );
      await file.rename(target);
      flattenedPaths.add(target);
      vacatedDirs.add(originalDir);
    }

    // 清理拍平后被搬空的原始子目录，不影响仍含其他文件的目录
    for (final dir in vacatedDirs) {
      _removeEmptyDirsUpwards(dir, sourceDir);
    }

    // Step 2/3：基于 YAML 层级关系创建新目录结构
    final createdDirs = <String>{};
    for (final segments in leafMap.values) {
      final dirPath = p.joinAll([sourceDir, ...segments]);
      if (createdDirs.add(dirPath)) {
        await Directory(dirPath).create(recursive: true);
      }
    }

    // Step 4：按 title 字段匹配并移动
    var moved = 0;
    var missingTitle = 0;
    var unmatched = 0;
    final warnings = <ReclassifyWarning>[];

    for (final path in flattenedPaths) {
      final file = File(path);
      final title = _extractTitle(await file.readAsString());
      final relativePath = p.basename(path);

      if (title == null) {
        missingTitle++;
        warnings.add(
          ReclassifyWarning(
            relativePath: relativePath,
            type: ReclassifyWarningType.missingTitle,
          ),
        );
        continue;
      }

      final segments = leafMap[title];
      if (segments == null) {
        unmatched++;
        warnings.add(
          ReclassifyWarning(
            relativePath: relativePath,
            type: ReclassifyWarningType.unmatchedTitle,
          ),
        );
        continue;
      }

      final targetDir = p.joinAll([sourceDir, ...segments]);
      final targetPath = _resolveCollisionPath(
        p.join(targetDir, p.basename(path)),
      );
      await file.rename(targetPath);
      moved++;
    }

    return ReclassifyOutcome(
      stats: ReclassifyStats(
        totalFiles: flattenedPaths.length,
        movedFiles: moved,
        missingTitleFiles: missingTitle,
        unmatchedFiles: unmatched,
      ),
      warnings: warnings,
    );
  }

  // ── Front Matter 中的 title 字段提取 ─────────────────────────────────────────

  String? _extractTitle(String content) {
    if (!content.startsWith('---')) return null;
    final fmEnd = content.indexOf('\n---', 3);
    if (fmEnd == -1) return null;
    final fmBlock = content.substring(3, fmEnd);
    try {
      final doc = loadYaml(fmBlock);
      if (doc is YamlMap) {
        final title = doc['title'];
        if (title != null) return title.toString();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  // ── 拍平后清理原始空目录（自下而上，遇到非空目录即停止） ──────────────────────

  void _removeEmptyDirsUpwards(String dirPath, String stopAt) {
    var current = Directory(dirPath);
    while (p.isWithin(stopAt, current.path)) {
      if (!current.existsSync() || current.listSync().isNotEmpty) break;
      current.deleteSync();
      current = current.parent;
    }
  }

  // ── 目标路径冲突时自动重命名（file.md → file_1.md → file_2.md ...） ──────────

  String _resolveCollisionPath(String desiredPath) {
    if (!File(desiredPath).existsSync()) return desiredPath;
    final dir = p.dirname(desiredPath);
    final ext = p.extension(desiredPath);
    final baseName = p.basenameWithoutExtension(desiredPath);
    var counter = 1;
    String candidate;
    do {
      candidate = p.join(dir, '${baseName}_$counter$ext');
      counter++;
    } while (File(candidate).existsSync());
    return candidate;
  }
}
