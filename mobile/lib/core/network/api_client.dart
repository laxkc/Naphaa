import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    int connectTimeoutSeconds = 10,
    int receiveTimeoutSeconds = 15,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: Duration(seconds: connectTimeoutSeconds),
               receiveTimeout: Duration(seconds: receiveTimeoutSeconds),
             ),
           );

  final Dio _dio;

  Dio get dio => _dio;
}
