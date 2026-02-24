import 'package:dio/dio.dart';

class SyncPushFailure {
  const SyncPushFailure({
    required this.opId,
    required this.code,
    required this.message,
  });

  final String? opId;
  final String code;
  final String message;
}

class SyncPushResult {
  const SyncPushResult({
    required this.ackedOpIds,
    required this.failedEvents,
  });

  final List<String> ackedOpIds;
  final List<SyncPushFailure> failedEvents;
}

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

  Future<Map<String, dynamic>> refresh({
    required String refreshToken,
  }) async {
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

  Future<SyncPushResult> pushSync(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) {
      return SyncPushResult(ackedOpIds: const [], failedEvents: const []);
    }
    final res = await _dio.post('/sync/push', data: {'events': events});
    final body = Map<String, dynamic>.from(res.data as Map? ?? const {});
    final acked = (body['acked_op_ids'] as List? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final failed =
        (body['failed_events'] as List? ?? const [])
            .whereType<Map>()
            .map((raw) => Map<String, dynamic>.from(raw))
            .map(
              (raw) => SyncPushFailure(
                opId: raw['op_id']?.toString(),
                code: raw['code']?.toString() ?? 'SYNC_FAILED',
                message:
                    raw['message']?.toString() ?? 'Failed to apply sync event',
              ),
            )
            .toList();
    return SyncPushResult(ackedOpIds: acked, failedEvents: failed);
  }

  Future<Map<String, dynamic>> pullSync({
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
    return Map<String, dynamic>.from(res.data as Map);
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

  Future<void> logout({required String refreshToken}) async {
    await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
  }
}
