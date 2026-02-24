import 'package:dio/dio.dart';

class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this.localeCode);

  final String localeCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = localeCode == 'ne' ? 'ne-NP' : 'en-US';
    super.onRequest(options, handler);
  }
}
