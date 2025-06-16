import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants.dart';
import 'base_response.dart';

class ApiClient {
  static final _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  static String? get _token => Hive.box('authBox').get('authToken');

  static Options get _options => Options(
    headers: {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': _token,
    },
  );

  static Future<BaseResponse<T>> get<T>(
      String path,
      T Function(dynamic) fromJson,
      ) async {
    try {
      final response = await _dio.get(path, options: _options);
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  static Future<BaseResponse<T>> post<T>(
      String path,
      T Function(dynamic) fromJson, {
        dynamic data,
      }) async {
    try {
      final response = await _dio.post(path, data: data, options: _options);
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  static Future<BaseResponse<T>> put<T>(
      String path,
      T Function(dynamic) fromJson, {
        dynamic data,
      }) async {
    try {
      final response = await _dio.put(path, data: data, options: _options);
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  static Future<BaseResponse<bool>> delete(String path) async {
    try {
      final response = await _dio.delete(path, options: _options);
      return BaseResponse.success(
        response.statusCode == 200 || response.statusCode == 204,
        message: 'Deleted successfully',
      );
    } catch (e) {
      return _handleError<bool>(e);
    }
  }

  static BaseResponse<T> _handleResponse<T>(
      Response response,
      T Function(dynamic) fromJson,
      ) {
    try {
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        if (response.data != null) {
          return BaseResponse.success(fromJson(response.data));
        } else {
          return BaseResponse.error('Empty response data');
        }
      } else {
        return BaseResponse.error('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      print('Response parsing error: $e'); // Add debugging
      return BaseResponse.error('Failed to parse response: $e');
    }
  }

  static BaseResponse<T> _handleError<T>(dynamic error) {
    String errorMessage = 'Unknown error occurred';

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Server error: ${error.response?.statusCode}';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request cancelled';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Connection error';
          break;
        default:
          errorMessage = 'Network error: ${error.message}';
      }
    } else {
      errorMessage = 'Unknown error: ${error.toString()}';
    }

    print('API Error: $errorMessage'); // Add debugging
    return BaseResponse.error(errorMessage);
  }
}
