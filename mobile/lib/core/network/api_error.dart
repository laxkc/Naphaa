import 'package:dio/dio.dart';

class ApiError {
  ApiError({required this.statusCode, this.code, required this.message});

  final int? statusCode;
  final String? code;
  final String message;

  static ApiError fromDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is Map<String, dynamic>) {
        return ApiError(
          statusCode: status,
          code: detail['code']?.toString(),
          message:
              detail['detail']?.toString() ??
              detail['code']?.toString() ??
              'Request failed',
        );
      }
      if (detail is String && detail.isNotEmpty) {
        return ApiError(statusCode: status, message: detail);
      }
    }

    return ApiError(
      statusCode: status,
      message: error.message ?? 'Request failed',
    );
  }
}
