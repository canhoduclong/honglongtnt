import 'package:dio/dio.dart';

import '../utils/api_exception.dart';
import '../utils/app_config.dart';
import 'storage_service.dart';

class ApiService {
  ApiService(this._storage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        followRedirects: false,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.clearSession();
          }
          handler.next(error);
        },
      ),
    );
  }

  final StorageService _storage;
  late final Dio dio;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await dio.get(path, queryParameters: query);
      return _normalize(response);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? data}) async {
    try {
      final response = await dio.post(path, data: data);
      return _normalize(response);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> postForm(String path, FormData data) async {
    try {
      final response = await dio.post(
        path,
        data: data,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );
      return _normalize(response);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> putJson(String path, {Object? data}) async {
    try {
      final response = await dio.put(path, data: data);
      return _normalize(response);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> deleteJson(String path, {Object? data}) async {
    try {
      final response = await dio.delete(path, data: data);
      return _normalize(response);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Map<String, dynamic> _normalize(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'];
      if (success == false) {
        throw ApiException(
          (data['message'] ?? 'Yeu cau that bai').toString(),
          statusCode: response.statusCode,
        );
      }
      return data;
    }
    throw ApiException(
      'Dinh dang phan hoi API khong hop le',
      statusCode: response.statusCode,
    );
  }

  ApiException _toApiException(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(
        data['message'].toString(),
        statusCode: error.response?.statusCode,
      );
    }
    if (error.response?.statusCode == 301 ||
        error.response?.statusCode == 302) {
      final location = error.response?.headers.value('location') ?? '';
      return ApiException(
        'API dang tra ve redirect HTML${location.isNotEmpty ? ' toi $location' : ''}. Kiem tra API_BASE_URL va endpoint /api/mobile.',
        statusCode: error.response?.statusCode,
      );
    }
    return ApiException(
      error.message ?? 'Khong ket noi duoc may chu',
      statusCode: error.response?.statusCode,
    );
  }
}
