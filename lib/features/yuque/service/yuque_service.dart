import 'package:dio/dio.dart';
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
