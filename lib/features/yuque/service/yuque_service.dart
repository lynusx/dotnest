import 'package:dio/dio.dart';
import '../model/yuque_doc.dart';
import '../model/yuque_repo.dart';

/// 语雀 OpenAPI 服务层，基于 dio 封装 HTTP 请求
class YuqueService {
  static const _baseUrl = 'https://www.yuque.com';

  final Dio _dio;

  YuqueService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

  // ── 知识库文档 ─────────────────────────────────────────────────────────────

  /// GET /api/v2/repos/{book_id}/docs — 单页，返回 (total, docs)
  Future<(int, List<YuqueDoc>)> _fetchDocPage(
    String token,
    int bookId,
    int offset,
    int limit,
  ) async {
    final response = await _dio.get(
      '/api/v2/repos/$bookId/docs',
      queryParameters: {'offset': offset, 'limit': limit},
      options: Options(headers: {'X-Auth-Token': token}),
    );
    final meta = response.data['meta'] as Map<String, dynamic>?;
    final total = (meta?['total'] as num?)?.toInt() ?? 0;
    final data = response.data['data'] as List<dynamic>;
    final docs = data
        .map((e) => YuqueDoc.fromJson(e as Map<String, dynamic>))
        .toList();
    return (total, docs);
  }

  /// GET /api/v2/repos/{book_id}/docs — 自动翻页，获取全部文档
  Future<(List<YuqueDoc>, int)> fetchAllDocs(String token, int bookId) async {
    try {
      const pageSize = 100;
      final (total, firstPage) =
          await _fetchDocPage(token, bookId, 0, pageSize);
      final docs = List<YuqueDoc>.from(firstPage);

      for (int offset = pageSize; offset < total; offset += pageSize) {
        final (_, page) =
            await _fetchDocPage(token, bookId, offset, pageSize);
        docs.addAll(page);
      }
      return (docs, total);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) throw Exception('Token 无效或未通过鉴权');
      if (status == 403) throw Exception('无访问权限');
      if (status == 404) throw Exception('知识库 "$bookId" 不存在');
      if (status == 429) throw Exception('请求频率超限，请稍后重试');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('请求超时，请检查网络连接');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('网络连接失败，请检查网络');
      }
      throw Exception('请求失败: ${e.message}');
    }
  }

  // ── 创建文档 ───────────────────────────────────────────────────────────────

  /// POST /api/v2/repos/{book_id}/docs — 创建单个文档，返回新文档 ID
  Future<int> createDoc(
    String token,
    int bookId,
    String slug,
    String title,
    String body,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v2/repos/$bookId/docs',
        data: {'slug': slug, 'title': title, 'body': body},
        options: Options(headers: {'X-Auth-Token': token}),
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['id'] as num).toInt();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) throw Exception('Token 无效或未通过鉴权');
      if (status == 403) throw Exception('无操作权限');
      if (status == 404) throw Exception('知识库 "$bookId" 不存在');
      if (status == 422) throw Exception('请求参数校验失败');
      if (status == 429) throw Exception('请求频率超限，请稍后重试');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('请求超时，请检查网络连接');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('网络连接失败，请检查网络');
      }
      throw Exception('请求失败: ${e.message}');
    }
  }

  // ── 知识库列表 ─────────────────────────────────────────────────────────────

  /// GET /api/v2/users/{login}/repos
  Future<List<YuqueRepo>> fetchRepos(String token, String login) async {
    try {
      final response = await _dio.get(
        '/api/v2/users/$login/repos',
        options: Options(headers: {'X-Auth-Token': token}),
      );

      final data = response.data['data'] as List<dynamic>;
      return data
          .map((e) => YuqueRepo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) throw Exception('Token 无效或未通过鉴权');
      if (status == 403) throw Exception('无访问权限');
      if (status == 404) throw Exception('用户 "$login" 不存在');
      if (status == 429) throw Exception('请求频率超限，请稍后重试');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('请求超时，请检查网络连接');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('网络连接失败，请检查网络');
      }
      throw Exception('请求失败: ${e.message}');
    }
  }
}
