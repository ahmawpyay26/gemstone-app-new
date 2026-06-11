import 'package:dio/dio.dart' as dio;
import '../constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late dio.Dio _dio;
  final FlutterSecureStorage _secureStorage;

  ApiClient({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: Duration(seconds: AppConstants.connectionTimeout),
        receiveTimeout: Duration(seconds: AppConstants.receiveTimeout),
        contentType: 'application/json',
        responseType: dio.ResponseType.json,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    dio.RequestOptions options,
    dio.RequestInterceptorHandler handler,
  ) async {
    try {
      // Get access token from secure storage
      final token = await _secureStorage.read(
        key: AppConstants.storageKeyAccessToken,
      );

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      print('[API Request] ${options.method} ${options.path}');
      return handler.next(options);
    } catch (e) {
      print('[API Request Error] $e');
      return handler.next(options);
    }
  }

  Future<void> _onResponse(
    dio.Response response,
    dio.ResponseInterceptorHandler handler,
  ) async {
    print('[API Response] ${response.statusCode} ${response.requestOptions.path}');
    return handler.next(response);
  }

  Future<void> _onError(
    dio.DioException error,
    dio.ErrorInterceptorHandler handler,
  ) async {
    print('[API Error] ${error.response?.statusCode} ${error.message}');

    // Handle 401 Unauthorized - token might be expired
    if (error.response?.statusCode == 401) {
      // Try to refresh token
      try {
        await _refreshToken();
        // Retry the request
        return handler.resolve(await _dio.request(
          error.requestOptions.path,
          options: dio.Options(
            method: error.requestOptions.method,
            headers: error.requestOptions.headers,
          ),
          data: error.requestOptions.data,
          queryParameters: error.requestOptions.queryParameters,
        ));
      } catch (e) {
        print('[Token Refresh Error] $e');
        return handler.next(error);
      }
    }

    return handler.next(error);
  }

  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(
        key: AppConstants.storageKeyRefreshToken,
      );

      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _dio.post(
        AppConstants.authRefreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        await _secureStorage.write(
          key: AppConstants.storageKeyAccessToken,
          value: newAccessToken,
        );
      }
    } catch (e) {
      print('[Refresh Token Error] $e');
      rethrow;
    }
  }

  // GET request
  Future<dio.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  Future<dio.Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // PUT request
  Future<dio.Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request
  Future<dio.Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // PATCH request
  Future<dio.Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Close Dio instance
  void close() {
    _dio.close();
  }
}
