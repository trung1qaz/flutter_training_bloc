abstract class BaseResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;

  BaseResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory BaseResponse.success(T data, {String message = 'Success'}) {
    return _BaseResponseImpl(
      success: true,
      message: message,
      data: data,
    );
  }

  factory BaseResponse.error(String error, {String message = 'Error'}) {
    return _BaseResponseImpl(
      success: false,
      message: message,
      error: error,
    );
  }

  factory BaseResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic) fromJsonT,
      ) {
    return _BaseResponseImpl(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'],
    );
  }
}

class _BaseResponseImpl<T> extends BaseResponse<T> {
  _BaseResponseImpl({
    required bool success,
    required String message,
    T? data,
    String? error,
  }) : super(success: success, message: message, data: data, error: error);
}
