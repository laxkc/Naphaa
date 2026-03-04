import 'package:dio/dio.dart';

import 'models/sync_models.dart';

class BackendGateway {
  BackendGateway(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    String? businessName,
    String? localeDefault,
    String? currency,
  }) async {
    final payload = <String, dynamic>{'phone': phone, 'password': password};
    if (businessName != null && businessName.trim().isNotEmpty) {
      payload['business_name'] = businessName.trim();
    }
    if (localeDefault != null && localeDefault.isNotEmpty) {
      payload['locale_default'] = localeDefault;
    }
    if (currency != null && currency.isNotEmpty) {
      payload['currency'] = currency;
    }
    final res = await _dio.post('/auth/register', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'phone': phone, 'password': password},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> requestOtp({
    required String phone,
    required String localeDefault,
  }) async {
    final res = await _dio.post(
      '/auth/otp/request',
      data: {'phone': phone, 'locale_default': localeDefault},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    required String localeDefault,
  }) async {
    final res = await _dio.post(
      '/auth/otp/verify',
      data: {
        'phone': phone,
        'otp': otp,
        'locale_default': localeDefault,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    final res = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getStoreMe() async {
    final res = await _dio.get('/stores/me');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateStore({
    required String storeId,
    String? name,
    String? address,
    String? phone,
    String? businessType,
    String? localeDefault,
    String? currency,
    String? calendarMode,
    String? businessTimezone,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) payload['name'] = name.trim();
    if (address != null) payload['address'] = address.trim();
    if (phone != null) payload['phone'] = phone.trim();
    if (businessType != null) payload['business_type'] = businessType.trim();
    if (localeDefault != null && localeDefault.trim().isNotEmpty) {
      payload['locale_default'] = localeDefault.trim();
    }
    if (currency != null && currency.trim().isNotEmpty) {
      payload['currency'] = currency.trim();
    }
    if (calendarMode != null && calendarMode.trim().isNotEmpty) {
      payload['calendar_mode'] = calendarMode.trim().toUpperCase();
    }
    if (businessTimezone != null && businessTimezone.trim().isNotEmpty) {
      payload['business_timezone'] = businessTimezone.trim();
    }
    final res = await _dio.patch('/stores/$storeId', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getAuthMe() async {
    final res = await _dio.get('/auth/me');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> ensureStore({
    required String name,
    required String localeCode,
    required String currency,
  }) async {
    try {
      await _dio.get('/stores/me');
      return;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }

    await _dio.post(
      '/stores',
      data: {'name': name, 'locale_default': localeCode, 'currency': currency},
    );
  }

  Future<SyncPushResponseModel> pushSync(
    List<Map<String, dynamic>> events,
  ) async {
    if (events.isEmpty) {
      return const SyncPushResponseModel(ackedOpIds: [], failedEvents: []);
    }
    final res = await _dio.post('/sync/push', data: {'events': events});
    return SyncPushResponseModel.fromJson(
      Map<String, dynamic>.from(res.data as Map? ?? const {}),
    );
  }

  Future<SyncPullResponseModel> pullSync({
    String? since,
    String? cursor,
    int? limit,
  }) async {
    final params = <String, dynamic>{};
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    } else if (since != null && since.isNotEmpty) {
      params['since'] = since;
    }
    if (limit != null && limit > 0) {
      params['limit'] = limit;
    }
    final res = await _dio.get(
      '/sync/pull',
      queryParameters: params.isEmpty ? null : params,
    );
    return SyncPullResponseModel.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<Map<String, dynamic>> syncStatus() async {
    final res = await _dio.get('/sync/status');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getSummaryReport({
    String? fromDate,
    String? toDate,
  }) async {
    final params = <String, dynamic>{};
    if (fromDate != null && fromDate.isNotEmpty) params['from'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) params['to'] = toDate;
    final res = await _dio.get(
      '/reports/summary',
      queryParameters: params.isEmpty ? null : params,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getLedgerReport({
    String? fromDate,
    String? toDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (fromDate != null && fromDate.isNotEmpty) params['from'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) params['to'] = toDate;
    final res = await _dio.get('/reports/ledger', queryParameters: params);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getCustomerMetrics({
    bool overdueOnly = false,
    bool highRiskOnly = false,
    int limit = 200,
  }) async {
    final res = await _dio.get(
      '/metrics/customers',
      queryParameters: {
        'overdue_only': overdueOnly,
        'high_risk_only': highRiskOnly,
        'limit': limit,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getAlerts({
    String status = 'open',
    int limit = 100,
  }) async {
    final res = await _dio.get(
      '/alerts',
      queryParameters: {'status': status, 'limit': limit},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getProductMetrics({
    bool deadStockOnly = false,
    int limit = 200,
    int windowDays = 30,
    int deadStockDays = 30,
  }) async {
    final res = await _dio.get(
      '/metrics/products',
      queryParameters: {
        'dead_stock_only': deadStockOnly,
        'limit': limit,
        'window_days': windowDays,
        'dead_stock_days': deadStockDays,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getBusinessMetrics({
    String? fromDate,
    String? toDate,
  }) async {
    final params = <String, dynamic>{};
    if (fromDate != null && fromDate.isNotEmpty) params['from'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) params['to'] = toDate;
    final res = await _dio.get('/metrics/business', queryParameters: params);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> logout({required String refreshToken}) async {
    await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
  }
}
