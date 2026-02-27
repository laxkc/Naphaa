import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/customers/data/customers_repository.dart';
import '../../features/customers/domain/customer.dart';
import '../../features/customers/domain/customer_risk_metric.dart';
import '../../features/billing/data/billing_repository.dart';
import '../../features/billing/data/invoice_pdf_service.dart';
import '../../features/billing/domain/invoice_models.dart';
import '../../features/expenses/data/expenses_repository.dart';
import '../../features/expenses/domain/expense.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/products/data/products_repository.dart';
import '../../features/products/domain/product.dart';
import '../../features/products/domain/stock_movement.dart';
import '../../features/reports/domain/alert_item.dart';
import '../../features/reports/data/alerts_repository.dart';
import '../../features/reports/data/metrics_repository.dart';
import '../../features/sales/data/sales_repository.dart';
import '../../features/sales/domain/sale.dart';
import '../../features/reports/domain/ledger_entry.dart';
import '../../features/reports/domain/product_metric_item.dart';
import '../../features/sales/sales_controller.dart';
import '../../features/sales/sales_state.dart';
import '../network/api_client.dart';
import '../network/api_error.dart';
import '../network/backend_gateway.dart';
import '../network/session_service.dart';
import '../network/sync_service.dart';
import '../storage/local_db.dart';
import '../storage/preferences.dart';
import '../storage/secure_storage.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_queue.dart';
import '../sync/sync_error_mapper.dart';

final localDatabaseProvider = Provider<LocalDatabase>(
  (ref) => LocalDatabase.instance,
);

final preferencesProvider = Provider<AppPreferences>((ref) => AppPreferences());

final billingLanguageCodeProvider = FutureProvider<String>((ref) async {
  final settings = await ref.watch(preferencesProvider).getBillingSettings();
  final lang = (settings['language']?.toString() ?? '').trim().toLowerCase();
  if (lang == 'ne' || lang == 'en') return lang;
  return ref.watch(localeControllerProvider).languageCode;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);

final backendGatewayProvider = Provider<BackendGateway>(
  (ref) => BackendGateway(ref.watch(dioProvider)),
);

final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  (ref) => SecureTokenStorage(const FlutterSecureStorage()),
);

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(
    ref.watch(backendGatewayProvider),
    ref.watch(secureTokenStorageProvider),
    ref.watch(dioProvider),
  ),
);

class AuthController extends Notifier<AuthState> {
  SessionService get _session => ref.read(sessionServiceProvider);
  AppPreferences get _prefs => ref.read(preferencesProvider);

  @override
  AuthState build() {
    Future.microtask(() async {
      final token = await ref.read(secureTokenStorageProvider).getAccessToken();
      final phone = await _prefs.getUserPhone();
      final role = await _prefs.getUserRole();
      if (token != null && token.isNotEmpty) {
        state = state.copyWith(
          authenticated: true,
          phone: phone,
          role: role ?? 'owner',
          error: null,
        );
      }
    });
    return AuthState();
  }

  Future<void> login({required String phone, required String password}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final previousPhone = await _prefs.getUserPhone();
      final locale = ref.read(localeControllerProvider).languageCode;
      await _session.login(
        phone: phone,
        password: password,
        localeCode: locale,
      );
      await _handlePostAuthStoreScope(
        phone: phone,
        previousPhone: previousPhone,
      );
      await _prefs.setUserPhone(phone);
      final role = await _session.fetchCurrentUserRole(localeCode: locale);
      if (role != null && role.isNotEmpty) {
        await _prefs.setUserRole(role);
      }
      state = state.copyWith(
        loading: false,
        authenticated: true,
        phone: phone,
        role: role ?? state.role ?? 'owner',
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        authenticated: false,
        error: _authErrorMessage(e, isSignup: false),
      );
    }
  }

  Future<void> signup({
    required String businessName,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final previousPhone = await _prefs.getUserPhone();
      final locale = ref.read(localeControllerProvider).languageCode;
      await _session.signup(
        businessName: businessName,
        phone: phone,
        password: password,
        localeCode: locale,
      );
      await _handlePostAuthStoreScope(
        phone: phone,
        previousPhone: previousPhone,
      );
      await _prefs.setUserPhone(phone);
      final role = await _session.fetchCurrentUserRole(localeCode: locale);
      if (role != null && role.isNotEmpty) {
        await _prefs.setUserRole(role);
      }
      state = state.copyWith(
        loading: false,
        authenticated: true,
        phone: phone,
        role: role ?? state.role ?? 'owner',
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        authenticated: false,
        error: _authErrorMessage(e, isSignup: true),
      );
    }
  }

  Future<void> logout() async {
    await _session.logout();
    await _clearLocalBusinessStateForAccountSwitch();
    await _prefs.clearUserPhone();
    await _prefs.clearUserRole();
    await _prefs.clearActiveStoreId();
    state = AuthState();
  }

  void setRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final current = state.role?.trim().toLowerCase();
    if (current == normalized) return;
    state = state.copyWith(role: normalized);
  }

  String _authErrorMessage(Object error, {required bool isSignup}) {
    if (error is DioException) {
      final apiError = ApiError.fromDio(error);
      if (apiError.code == 'INVALID_CREDENTIALS' ||
          apiError.statusCode == 401) {
        return 'Invalid phone or password.';
      }
      if (apiError.code == 'PHONE_ALREADY_REGISTERED' ||
          apiError.statusCode == 409) {
        return isSignup
            ? 'Phone already exists. Please login instead.'
            : 'Account already exists. Please login.';
      }
      if (apiError.statusCode == 422) {
        return 'Please check your input and try again.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Cannot reach server. Check internet or backend status.';
      }
      if (apiError.message.isNotEmpty && apiError.message != 'Request failed') {
        return apiError.message;
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _handlePostAuthStoreScope({
    required String phone,
    required String? previousPhone,
  }) async {
    final gateway = ref.read(backendGatewayProvider);
    final store = await gateway.getStoreMe();
    final currentStoreId = store['id']?.toString();
    if (currentStoreId == null || currentStoreId.isEmpty) return;

    final previousStoreId = await _prefs.getActiveStoreId();
    final switchedStore =
        previousStoreId != null &&
        previousStoreId.isNotEmpty &&
        previousStoreId != currentStoreId;
    final switchedPhoneWithoutStoreMarker =
        (previousStoreId == null || previousStoreId.isEmpty) &&
        previousPhone != null &&
        previousPhone.isNotEmpty &&
        previousPhone != phone;

    if (switchedStore || switchedPhoneWithoutStoreMarker) {
      await _clearLocalBusinessStateForAccountSwitch();
    }

    await _prefs.setActiveStoreId(currentStoreId);
  }

  Future<void> _clearLocalBusinessStateForAccountSwitch() async {
    final db = ref.read(localDatabaseProvider);
    await db.reset();
    await _prefs.clearLastSyncCursor();
    await _prefs.clearLastSyncAt();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class LocaleController extends Notifier<Locale> {
  AppPreferences get _preferences => ref.read(preferencesProvider);

  @override
  Locale build() {
    Future.microtask(() async {
      try {
        await _load();
      } catch (_) {
        state = const Locale('ne');
      }
    });
    return const Locale('ne');
  }

  Future<void> _load() async {
    final code = await _preferences.getLocaleCode();
    state = Locale(code);
  }

  Future<void> setLocale(String code) async {
    await _preferences.setLocaleCode(code);
    state = Locale(code);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

final syncQueueProvider = Provider<SyncQueueService>(
  (ref) => SyncQueueService(ref.watch(localDatabaseProvider)),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    ref.watch(localDatabaseProvider),
    ref.watch(backendGatewayProvider),
    ref.watch(preferencesProvider),
    ref.watch(sessionServiceProvider),
  ),
);

final syncManagerProvider = Provider<SyncManager>(
  (ref) => SyncManager.remote(ref.watch(syncServiceProvider)),
);

typedef ConnectivityCheckFn =
    Future<List<ConnectivityResult>> Function({Connectivity? connectivity});

typedef ConnectivityChangesFn =
    Stream<List<ConnectivityResult>> Function({Connectivity? connectivity});

final syncConnectivityCheckProvider = Provider<ConnectivityCheckFn>((ref) {
  return ({Connectivity? connectivity}) {
    final c = connectivity ?? Connectivity();
    return c.checkConnectivity();
  };
});

final syncConnectivityChangesProvider = Provider<ConnectivityChangesFn>((ref) {
  return ({Connectivity? connectivity}) {
    final c = connectivity ?? Connectivity();
    return c.onConnectivityChanged;
  };
});

final syncCoordinatorDebounceDurationProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

final syncCoordinatorPeriodicDurationProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

class SyncStatusState {
  const SyncStatusState({
    this.online = true,
    this.syncing = false,
    this.pendingCount = 0,
    this.lastSuccessAt,
    this.lastError,
    this.lastDurationMs,
    this.lastPushed = 0,
    this.lastAcked = 0,
    this.lastFailed = 0,
    this.lastPulled = 0,
    this.lastApplied = 0,
  });

  final bool online;
  final bool syncing;
  final int pendingCount;
  final DateTime? lastSuccessAt;
  final String? lastError;
  final int? lastDurationMs;
  final int lastPushed;
  final int lastAcked;
  final int lastFailed;
  final int lastPulled;
  final int lastApplied;

  SyncStatusState copyWith({
    bool? online,
    bool? syncing,
    int? pendingCount,
    DateTime? lastSuccessAt,
    String? lastError,
    int? lastDurationMs,
    int? lastPushed,
    int? lastAcked,
    int? lastFailed,
    int? lastPulled,
    int? lastApplied,
    bool clearError = false,
  }) {
    return SyncStatusState(
      online: online ?? this.online,
      syncing: syncing ?? this.syncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastDurationMs: lastDurationMs ?? this.lastDurationMs,
      lastPushed: lastPushed ?? this.lastPushed,
      lastAcked: lastAcked ?? this.lastAcked,
      lastFailed: lastFailed ?? this.lastFailed,
      lastPulled: lastPulled ?? this.lastPulled,
      lastApplied: lastApplied ?? this.lastApplied,
    );
  }
}

class SyncCoordinatorController extends Notifier<SyncStatusState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _debounceTimer;
  AppLifecycleListener? _lifecycleListener;
  bool _inFlight = false;
  bool _started = false;
  int _failureCount = 0;
  DateTime? _backoffUntil;

  @override
  SyncStatusState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _connectivitySub?.cancel();
      _lifecycleListener?.dispose();
    });
    Future.microtask(_startIfNeeded);
    return const SyncStatusState();
  }

  Future<void> _startIfNeeded() async {
    if (_started) return;
    _started = true;

    await _refreshPendingCount();
    if (!ref.mounted) return;
    final connectivity = Connectivity();
    final initial = await ref.read(syncConnectivityCheckProvider)(
      connectivity: connectivity,
    );
    if (!ref.mounted) return;
    final initialOnline = initial.any((it) => it != ConnectivityResult.none);
    state = state.copyWith(online: initialOnline);

    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (state.online) {
          _scheduleSyncDebounced();
        }
      },
    );

    _connectivitySub = ref
        .read(syncConnectivityChangesProvider)(connectivity: connectivity)
        .listen((results) {
          final online = results.any((it) => it != ConnectivityResult.none);
          state = state.copyWith(online: online);
          if (online) {
            _scheduleSyncDebounced();
          }
        });

    if (initialOnline) {
      _scheduleSyncDebounced();
    }
  }

  void _scheduleSyncDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      ref.read(syncCoordinatorDebounceDurationProvider),
      _triggerSync,
    );
  }

  Future<void> triggerNow() async => _triggerSync();

  Future<void> _triggerSync() async {
    if (_inFlight) return;
    final now = DateTime.now();
    final backoffUntil = _backoffUntil;
    if (backoffUntil != null && now.isBefore(backoffUntil)) {
      return;
    }
    final auth = ref.read(authControllerProvider);
    if (!auth.authenticated) {
      await _refreshPendingCount();
      if (!ref.mounted) return;
      return;
    }

    _inFlight = true;
    state = state.copyWith(syncing: true, clearError: true);
    try {
      final localeCode = ref.read(localeControllerProvider).languageCode;
      final syncMeta = await ref
          .read(syncManagerProvider)
          .processPendingSyncWithMeta(localeCode: localeCode);
      final syncResult = syncMeta.result;
      await _refreshPendingCount();
      if (!ref.mounted) return;
      _failureCount = 0;
      _backoffUntil = null;
      final partialWarning =
          syncResult.hasFailures
              ? 'Sync completed with ${syncResult.failedEvents} failed item(s).'
              : null;
      state = state.copyWith(
        syncing: false,
        lastSuccessAt: DateTime.now(),
        lastError: partialWarning,
        lastDurationMs: syncMeta.durationMs,
        lastPushed: syncResult.pushedEvents,
        lastAcked: syncResult.ackedEvents,
        lastFailed: syncResult.failedEvents,
        lastPulled: syncResult.pulledEvents,
        lastApplied: syncResult.appliedEvents,
        clearError: !syncResult.hasFailures,
      );
      developer.log(
        'sync_coordinator result pending=${syncResult.pendingAtStart} pushed=${syncResult.pushedEvents} '
        'acked=${syncResult.ackedEvents} failed=${syncResult.failedEvents} pulled=${syncResult.pulledEvents} '
        'applied=${syncResult.appliedEvents} warning=${syncResult.hasFailures}',
        name: 'app.sync.coordinator',
      );

      // Refresh common local-first UI sources after sync updates local DB.
      ref.invalidate(productsListProvider);
      ref.invalidate(customersListProvider);
      ref.invalidate(expensesListProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(businessMetricsProvider);
      ref.invalidate(creditReportProvider);
      ref.invalidate(salesReportProvider);
      ref.invalidate(customerRiskMetricsProvider);
      ref.invalidate(alertsFeedProvider);
      ref.invalidate(alertsUnreadFeedProvider);
      ref.invalidate(customerMetricsReportProvider);
      ref.invalidate(productMetricsReportProvider);
    } catch (e) {
      if (e is SessionAuthException) {
        await ref.read(authControllerProvider.notifier).logout();
        if (!ref.mounted) return;
      }
      await _refreshPendingCount();
      if (!ref.mounted) return;
      final mapped = SyncErrorMapper.fromException(e);
      _failureCount += 1;
      final backoffSeconds = _computeBackoffSeconds(_failureCount);
      _backoffUntil = DateTime.now().add(Duration(seconds: backoffSeconds));
      state = state.copyWith(syncing: false, lastError: mapped.userMessage);
      developer.log(
        'sync_coordinator failure count=$_failureCount backoffSeconds=$backoffSeconds '
        'category=${mapped.category.name} detail=${mapped.developerDetail}',
        name: 'app.sync.coordinator',
      );
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _refreshPendingCount() async {
    if (!ref.mounted) return;
    final db = await ref.read(localDatabaseProvider).database;
    if (!ref.mounted) return;
    final row = await db.rawQuery("""
      SELECT COUNT(*) AS total
      FROM sync_queue
      WHERE synced = 0
        AND COALESCE(status, 'pending') IN ('pending', 'failed', 'blocked')
      """);
    if (!ref.mounted) return;
    final count = (row.first['total'] as num?)?.toInt() ?? 0;
    state = state.copyWith(pendingCount: count);
  }

  int _computeBackoffSeconds(int failures) {
    // 2, 4, 8, 16, 32, 60, 60...
    final exp = failures <= 0 ? 2 : (1 << failures);
    if (exp < 2) return 2;
    if (exp > 60) return 60;
    return exp;
  }
}

final syncCoordinatorProvider =
    NotifierProvider<SyncCoordinatorController, SyncStatusState>(
      SyncCoordinatorController.new,
    );

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(
    ref.watch(localDatabaseProvider),
    metricsRepository: ref.watch(metricsRepositoryProvider),
  ),
);

final customersRepositoryProvider = Provider<CustomersRepository>(
  (ref) => CustomersRepository(
    ref.watch(localDatabaseProvider),
    metricsRepository: ref.watch(metricsRepositoryProvider),
  ),
);

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepository(
    ref.watch(localDatabaseProvider),
    metricsRepository: ref.watch(metricsRepositoryProvider),
  ),
);

final alertsRepositoryProvider = Provider<AlertsRepository>(
  (ref) => AlertsRepository(ref.watch(localDatabaseProvider)),
);

final metricsRepositoryProvider = Provider<MetricsRepository>(
  (ref) => MetricsRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(alertsRepositoryProvider),
  ),
);

final productsListProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(productsRepositoryProvider).listProducts(),
);

final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final products = await ref.watch(productsListProvider.future);
  return products
      .where(
        (p) => p.lowStockThreshold > 0 && p.stockQty <= p.lowStockThreshold,
      )
      .toList()
    ..sort((a, b) => a.stockQty.compareTo(b.stockQty));
});

final customersListProvider = FutureProvider<List<Customer>>(
  (ref) => ref.watch(customersRepositoryProvider).listCustomers(),
);

final expensesListProvider = FutureProvider<List<Expense>>(
  (ref) => ref.watch(expensesRepositoryProvider).listExpenses(),
);

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepository(
    ref.watch(localDatabaseProvider),
    metricsRepository: ref.watch(metricsRepositoryProvider),
  ),
);

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => BillingRepository(ref.watch(localDatabaseProvider)),
);

final invoicePdfServiceProvider = Provider<InvoicePdfService>(
  (ref) => InvoicePdfService(
    ref.watch(billingRepositoryProvider),
    ref.watch(preferencesProvider),
  ),
);

final invoicesListProvider = FutureProvider<List<InvoiceRecord>>((ref) async {
  final storeId = await ref.watch(preferencesProvider).getActiveStoreId();
  if (storeId == null || storeId.isEmpty) return const [];
  return ref.watch(billingRepositoryProvider).listInvoices(businessId: storeId);
});

final invoiceDetailProvider = FutureProvider.autoDispose
    .family<InvoiceRecord?, String>((ref, invoiceId) {
      return ref.watch(billingRepositoryProvider).getInvoiceById(invoiceId);
    });

final invoiceItemsProvider = FutureProvider.autoDispose
    .family<List<InvoiceItemRecord>, String>((ref, invoiceId) {
      return ref.watch(billingRepositoryProvider).getInvoiceItems(invoiceId);
    });

final invoicePaymentsProvider = FutureProvider.autoDispose
    .family<List<InvoicePaymentRecord>, String>((ref, invoiceId) {
      return ref.watch(billingRepositoryProvider).getInvoicePayments(invoiceId);
    });

final salesControllerProvider = NotifierProvider<SalesController, SalesState>(
  SalesController.new,
);

class DashboardSummary {
  DashboardSummary({
    required this.todaySales,
    required this.todayExpenses,
    required this.creditOutstanding,
  });

  final double todaySales;
  final double todayExpenses;
  final double creditOutstanding;

  double get estimatedProfit => todaySales - todayExpenses;
}

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final salesRepo = ref.watch(salesRepositoryProvider);
  final localTodaySales = await salesRepo.todaySalesTotal();
  final localTodayExpenses = await salesRepo.todayExpenseTotal();
  final localCredit = await salesRepo.creditOutstanding();

  return DashboardSummary(
    todaySales: localTodaySales,
    todayExpenses: localTodayExpenses,
    creditOutstanding: localCredit,
  );
});

final appStartupProvider = FutureProvider<void>((ref) async {
  final isAuthenticated = ref.watch(
    authControllerProvider.select((auth) => auth.authenticated),
  );
  if (!isAuthenticated) return;
  final localeCode = ref.watch(localeControllerProvider).languageCode;
  final db = ref.watch(localDatabaseProvider);
  await db.seedIfEmpty();
  try {
    await ref.watch(sessionServiceProvider).ensureReady(localeCode: localeCode);
    await ref
        .watch(syncManagerProvider)
        .processPendingSync(localeCode: localeCode);
  } catch (_) {
    // App remains usable offline if backend/session bootstrap fails.
  }
});

final profileProvider = FutureProvider<ProfileData>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final phone =
      auth.phone ?? await ref.watch(preferencesProvider).getUserPhone();
  var role = auth.role ?? await ref.watch(preferencesProvider).getUserRole();
  String? storeName;
  String? storeAddress;
  String? storePhone;
  String? businessType;
  String? localeDefault;
  String? currency;
  try {
    final locale = ref.watch(localeControllerProvider).languageCode;
    await ref.watch(sessionServiceProvider).ensureReady(localeCode: locale);
    final gateway = ref.watch(backendGatewayProvider);

    // Prefer /auth/me because it includes user + store snapshot together.
    final profile = await gateway.getAuthMe();
    storeName = profile['store_name']?.toString();
    storeAddress = profile['store_address']?.toString();
    storePhone = profile['store_phone']?.toString();
    businessType = profile['business_type']?.toString();
    localeDefault = profile['locale_default']?.toString();
    currency = profile['currency']?.toString();
    final apiRole = profile['role']?.toString().trim().toLowerCase();
    if (apiRole != null && apiRole.isNotEmpty) {
      role = apiRole;
      await ref.watch(preferencesProvider).setUserRole(apiRole);
      final currentRole = auth.role?.trim().toLowerCase();
      if (currentRole != apiRole) {
        ref.read(authControllerProvider.notifier).setRole(apiRole);
      }
    }

    final missingStoreName = (storeName?.trim().isEmpty ?? true);
    final missingLocaleDefault = (localeDefault?.trim().isEmpty ?? true);
    final missingStoreAddress = (storeAddress?.trim().isEmpty ?? true);
    final missingStorePhone = (storePhone?.trim().isEmpty ?? true);
    final missingBusinessType = (businessType?.trim().isEmpty ?? true);
    final missingCurrency = (currency?.trim().isEmpty ?? true);
    if (missingStoreName ||
        missingLocaleDefault ||
        missingStoreAddress ||
        missingStorePhone ||
        missingBusinessType ||
        missingCurrency) {
      final store = await gateway.getStoreMe();
      storeName =
          storeName?.trim().isNotEmpty == true
              ? storeName
              : store['name']?.toString();
      storeAddress =
          storeAddress?.trim().isNotEmpty == true
              ? storeAddress
              : store['address']?.toString();
      storePhone =
          storePhone?.trim().isNotEmpty == true
              ? storePhone
              : store['phone']?.toString();
      businessType =
          businessType?.trim().isNotEmpty == true
              ? businessType
              : store['business_type']?.toString();
      localeDefault =
          localeDefault?.trim().isNotEmpty == true
              ? localeDefault
              : store['locale_default']?.toString();
      currency =
          currency?.trim().isNotEmpty == true
              ? currency
              : store['currency']?.toString();
    }
  } catch (_) {
    // Offline or unauthenticated fallback
  }
  return ProfileData(
    phone: phone,
    storeName: storeName,
    storeAddress: storeAddress,
    storePhone: storePhone,
    businessType: businessType,
    localeDefault: localeDefault,
    currency: currency,
    role: role,
  );
});

// ─── Sales list & detail providers ───────────────────────────────────────────

class SalesListParams {
  const SalesListParams({this.fromDate, this.toDate, this.customerId});

  final DateTime? fromDate;
  final DateTime? toDate;
  final String? customerId;

  @override
  bool operator ==(Object other) =>
      other is SalesListParams &&
      fromDate == other.fromDate &&
      toDate == other.toDate &&
      customerId == other.customerId;

  @override
  int get hashCode => Object.hash(fromDate, toDate, customerId);
}

final salesListProvider = FutureProvider.autoDispose
    .family<List<Sale>, SalesListParams>((ref, params) {
      final repo = ref.watch(salesRepositoryProvider);
      return repo.listSales(
        fromDate: params.fromDate,
        toDate: params.toDate,
        customerId: params.customerId,
      );
    });

final saleDetailProvider = FutureProvider.autoDispose.family<Sale?, String>((
  ref,
  id,
) {
  return ref.watch(salesRepositoryProvider).getSaleById(id);
});

// ─── Product detail providers ─────────────────────────────────────────────────

final productDetailProvider = FutureProvider.autoDispose
    .family<Product?, String>((ref, id) {
      return ref.watch(productsRepositoryProvider).getProductById(id);
    });

final stockMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, String>((ref, productId) {
      return ref.watch(productsRepositoryProvider).getStockMovements(productId);
    });

// ─── Customer detail providers ────────────────────────────────────────────────

final customerDetailProvider = FutureProvider.autoDispose
    .family<Customer?, String>((ref, id) {
      return ref.watch(customersRepositoryProvider).getCustomerById(id);
    });

final customerLedgerProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, customerId) {
      return ref
          .watch(customersRepositoryProvider)
          .getCustomerLedger(customerId);
    });

final customerRiskMetricsProvider =
    FutureProvider.autoDispose<Map<String, CustomerRiskMetric>>((ref) async {
      final locale = ref.watch(localeControllerProvider).languageCode;
      try {
        await ref.watch(sessionServiceProvider).ensureReady(localeCode: locale);
        final body = await ref
            .watch(backendGatewayProvider)
            .getCustomerMetrics(limit: 500);
        final items =
            (body['items'] as List? ?? const [])
                .whereType<Map>()
                .map(
                  (e) =>
                      CustomerRiskMetric.fromJson(Map<String, dynamic>.from(e)),
                )
                .where((m) => m.customerId.isNotEmpty)
                .toList();
        return {for (final m in items) m.customerId: m};
      } catch (_) {
        return _loadCachedCustomerRiskMetricsMap(ref);
      }
    });

class CustomerMetricsQueryParams {
  const CustomerMetricsQueryParams({
    this.overdueOnly = false,
    this.highRiskOnly = false,
    this.limit = 200,
  });

  final bool overdueOnly;
  final bool highRiskOnly;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is CustomerMetricsQueryParams &&
      overdueOnly == other.overdueOnly &&
      highRiskOnly == other.highRiskOnly &&
      limit == other.limit;

  @override
  int get hashCode => Object.hash(overdueOnly, highRiskOnly, limit);
}

final customerMetricsReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, CustomerMetricsQueryParams>((
      ref,
      params,
    ) async {
      final locale = ref.watch(localeControllerProvider).languageCode;
      try {
        await ref.watch(sessionServiceProvider).ensureReady(localeCode: locale);
        return ref
            .watch(backendGatewayProvider)
            .getCustomerMetrics(
              overdueOnly: params.overdueOnly,
              highRiskOnly: params.highRiskOnly,
              limit: params.limit,
            );
      } catch (_) {
        return _loadCachedCustomerMetricsReport(ref, params);
      }
    });

final alertReadIdsProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) async {
  final prefs = ref.watch(preferencesProvider);
  final storeId = await prefs.getActiveStoreId();
  return prefs.getReadAlertIds(storeId: storeId);
});

final alertsUnreadFeedProvider = FutureProvider.autoDispose<List<AlertItem>>((
  ref,
) async {
  final alerts = await ref.watch(alertsFeedProvider.future);
  final readIds = await ref.watch(alertReadIdsProvider.future);
  return alerts.where((a) => !readIds.contains(a.id)).toList();
});

class AlertReadController {
  AlertReadController(this._ref);
  final Ref _ref;

  Future<void> markRead(String alertId) async {
    final prefs = _ref.read(preferencesProvider);
    final storeId = await prefs.getActiveStoreId();
    await prefs.markAlertRead(alertId, storeId: storeId);
    _ref.invalidate(alertReadIdsProvider);
    _ref.invalidate(alertsUnreadFeedProvider);
  }

  Future<void> markAllRead(Iterable<String> alertIds) async {
    final prefs = _ref.read(preferencesProvider);
    final storeId = await prefs.getActiveStoreId();
    await prefs.markAlertsRead(alertIds, storeId: storeId);
    _ref.invalidate(alertReadIdsProvider);
    _ref.invalidate(alertsUnreadFeedProvider);
  }
}

final alertReadControllerProvider = Provider<AlertReadController>((ref) {
  return AlertReadController(ref);
});

final alertsFeedProvider = FutureProvider.autoDispose<List<AlertItem>>((
  ref,
) async {
  final locale = ref.watch(localeControllerProvider).languageCode;
  try {
    await ref.watch(sessionServiceProvider).ensureReady(localeCode: locale);
    final body = await ref.watch(backendGatewayProvider).getAlerts(limit: 100);
    final items =
        (body['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => AlertItem.fromJson(Map<String, dynamic>.from(e)))
            .where((a) => a.id.isNotEmpty)
            .toList();
    items.sort((a, b) {
      final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return items;
  } catch (_) {
    return _loadCachedAlerts(ref);
  }
});

class ProductMetricsQueryParams {
  const ProductMetricsQueryParams({
    this.deadStockOnly = false,
    this.limit = 200,
    this.windowDays = 30,
    this.deadStockDays = 30,
  });

  final bool deadStockOnly;
  final int limit;
  final int windowDays;
  final int deadStockDays;

  @override
  bool operator ==(Object other) =>
      other is ProductMetricsQueryParams &&
      deadStockOnly == other.deadStockOnly &&
      limit == other.limit &&
      windowDays == other.windowDays &&
      deadStockDays == other.deadStockDays;

  @override
  int get hashCode =>
      Object.hash(deadStockOnly, limit, windowDays, deadStockDays);
}

final productMetricsReportProvider = FutureProvider.autoDispose.family<
  Map<String, dynamic>,
  ProductMetricsQueryParams
>((ref, params) async {
  final locale = ref.watch(localeControllerProvider).languageCode;
  try {
    await ref.watch(sessionServiceProvider).ensureReady(localeCode: locale);
    final body = await ref
        .watch(backendGatewayProvider)
        .getProductMetrics(
          deadStockOnly: params.deadStockOnly,
          limit: params.limit,
          windowDays: params.windowDays,
          deadStockDays: params.deadStockDays,
        );
    final items =
        (body['items'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (e) => ProductMetricItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .where((p) => p.productId.isNotEmpty)
            .toList();
    return {
      'items': items,
      'total_products': body['total_products'] ?? items.length,
      'dead_stock_count': body['dead_stock_count'] ?? 0,
      'dead_stock_value_total': body['dead_stock_value_total'] ?? 0,
      'computed_at': body['computed_at'],
    };
  } catch (_) {
    return _loadCachedProductMetricsReport(ref, params);
  }
});

final businessMetricsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final locale = ref.watch(localeControllerProvider).languageCode;
      try {
        await ref.watch(sessionServiceProvider).ensureReady(localeCode: locale);
        return ref.watch(backendGatewayProvider).getBusinessMetrics();
      } catch (_) {
        return _loadCachedBusinessMetrics(ref);
      }
    });

// ─── Reports providers ────────────────────────────────────────────────────────

class ReportParams {
  const ReportParams({required this.fromDate, required this.toDate});
  final DateTime fromDate;
  final DateTime toDate;

  @override
  bool operator ==(Object other) =>
      other is ReportParams &&
      fromDate == other.fromDate &&
      toDate == other.toDate;

  @override
  int get hashCode => Object.hash(fromDate, toDate);
}

final salesReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ReportParams>((ref, params) async {
      final repo = ref.watch(salesRepositoryProvider);
      final sales = await repo.listSales(
        fromDate: params.fromDate,
        toDate: params.toDate,
      );
      double totalRevenue = 0;
      double cashTotal = 0;
      double creditTotal = 0;
      for (final s in sales) {
        totalRevenue += s.totalAmount;
        if (s.saleType == 'CASH') cashTotal += s.totalAmount;
        if (s.saleType == 'CREDIT') creditTotal += s.totalAmount;
      }
      return {
        'total_revenue': totalRevenue,
        'total_transactions': sales.length,
        'avg_sale': sales.isEmpty ? 0.0 : totalRevenue / sales.length,
        'cash_total': cashTotal,
        'credit_total': creditTotal,
        'sales': sales,
      };
    });

final creditReportProvider = FutureProvider.autoDispose<List<Customer>>((
  ref,
) async {
  final customers =
      await ref.watch(customersRepositoryProvider).listCustomers();
  return customers.where((c) => c.balance > 0).toList()
    ..sort((a, b) => b.balance.compareTo(a.balance));
});

final ledgerReportProvider = FutureProvider.autoDispose<List<LedgerEntryItem>>((
  ref,
) async {
  final locale = ref.watch(localeControllerProvider).languageCode;
  await ref.watch(sessionServiceProvider).ensureReady(localeCode: locale);
  final body = await ref
      .watch(backendGatewayProvider)
      .getLedgerReport(page: 1, pageSize: 100);
  final items =
      (body['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => LedgerEntryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  return items;
});

Future<Map<String, CustomerRiskMetric>> _loadCachedCustomerRiskMetricsMap(
  Ref ref,
) async {
  final db = await ref.read(localDatabaseProvider).database;
  final rows = await db.query('customer_metrics');
  final metrics =
      rows
          .map((row) {
            final rawFactors = row['explanation_json']?.toString();
            Object? factors;
            if (rawFactors != null && rawFactors.isNotEmpty) {
              try {
                factors = jsonDecode(rawFactors);
              } catch (_) {}
            }
            return CustomerRiskMetric.fromJson({
              'customer_id': row['customer_id'],
              'outstanding_amount': row['outstanding_amount'],
              'oldest_due_days': row['oldest_due_days'],
              'avg_days_to_pay': row['avg_days_to_pay'],
              'on_time_rate': row['on_time_rate'],
              'payment_frequency_30d': row['payment_frequency_30d'],
              'risk_score': row['risk_score'],
              'risk_level': row['risk_level'],
              'factors': factors,
            });
          })
          .where((m) => m.customerId.isNotEmpty)
          .toList();
  return {for (final m in metrics) m.customerId: m};
}

Future<Map<String, dynamic>> _loadCachedCustomerMetricsReport(
  Ref ref,
  CustomerMetricsQueryParams params,
) async {
  final db = await ref.read(localDatabaseProvider).database;
  final rows = await db.rawQuery('''
    SELECT
      cm.customer_id,
      cm.outstanding_amount,
      cm.oldest_due_days,
      cm.avg_days_to_pay,
      cm.on_time_rate,
      cm.payment_frequency_30d,
      cm.risk_score,
      cm.risk_level,
      cm.explanation_json,
      cm.computed_at,
      c.name AS customer_name,
      c.phone AS phone
    FROM customer_metrics cm
    LEFT JOIN customers c ON c.id = cm.customer_id
    WHERE COALESCE(c.is_deleted, 0) = 0 OR c.id IS NULL
  ''');

  final items = <Map<String, dynamic>>[];
  double totalOutstanding = 0;
  double totalOverdue = 0;
  int highRiskCount = 0;
  final totals = <String, double>{
    'd0_7': 0,
    'd8_30': 0,
    'd31_60': 0,
    'd60_plus': 0,
  };

  for (final row in rows) {
    final riskLevel = (row['risk_level'] ?? 'green').toString().toLowerCase();
    final oldestDueDays = _rowToInt(row['oldest_due_days']);
    final outstanding = _rowToDouble(row['outstanding_amount']);
    if (params.overdueOnly && oldestDueDays <= 0) continue;
    if (params.highRiskOnly && riskLevel != 'red') continue;

    final bucket = _approxAgingFromOldestDue(oldestDueDays, outstanding);
    totals[bucket] = (totals[bucket] ?? 0) + outstanding;
    totalOutstanding += outstanding;
    if (oldestDueDays > 0) totalOverdue += outstanding;
    if (riskLevel == 'red') highRiskCount += 1;

    Object? factors;
    final rawFactors = row['explanation_json']?.toString();
    if (rawFactors != null && rawFactors.isNotEmpty) {
      try {
        factors = jsonDecode(rawFactors);
      } catch (_) {}
    }
    items.add({
      'customer_id': row['customer_id'],
      'customer_name': (row['customer_name'] ?? 'Customer').toString(),
      'phone': row['phone']?.toString(),
      'outstanding_amount': outstanding,
      'oldest_due_days': oldestDueDays,
      'avg_days_to_pay': _rowToDouble(row['avg_days_to_pay']),
      'on_time_rate': _rowToDouble(row['on_time_rate']),
      'payment_frequency_30d': _rowToDouble(row['payment_frequency_30d']),
      'risk_score': _rowToInt(row['risk_score']),
      'risk_level': riskLevel,
      'factors': factors,
      // Offline cache approximation: exact invoice bucket splits are not stored
      // in local customer_metrics cache, so outstanding is placed into a single
      // bucket based on oldest_due_days.
      'aging': {
        'd0_7': bucket == 'd0_7' ? outstanding : 0,
        'd8_30': bucket == 'd8_30' ? outstanding : 0,
        'd31_60': bucket == 'd31_60' ? outstanding : 0,
        'd60_plus': bucket == 'd60_plus' ? outstanding : 0,
      },
      'computed_at': row['computed_at']?.toString(),
    });
  }

  items.sort((a, b) {
    final ao = _rowToDouble(a['outstanding_amount']);
    final bo = _rowToDouble(b['outstanding_amount']);
    final cmpAmt = bo.compareTo(ao);
    if (cmpAmt != 0) return cmpAmt;
    return (a['customer_name']?.toString() ?? '').compareTo(
      b['customer_name']?.toString() ?? '',
    );
  });

  final limited = items.take(params.limit).toList();
  return {
    'items': limited,
    'total_outstanding': totalOutstanding,
    'total_overdue': totalOverdue,
    'high_risk_count': highRiskCount,
    'totals': totals,
    'source': 'local_cache',
  };
}

Future<List<AlertItem>> _loadCachedAlerts(Ref ref) async {
  final db = await ref.read(localDatabaseProvider).database;
  final rows = await db.query(
    'alerts',
    where: 'resolved_at IS NULL',
    orderBy: 'created_at DESC',
    limit: 100,
  );
  return rows
      .map((row) {
        Object? actionPayload;
        final rawPayload = row['action_payload_json']?.toString();
        if (rawPayload != null && rawPayload.isNotEmpty) {
          try {
            actionPayload = jsonDecode(rawPayload);
          } catch (_) {}
        }
        return AlertItem.fromJson({
          'id': row['id'],
          'type': row['type'],
          'severity': row['severity'],
          'title': row['title'],
          'body': row['body'],
          'entity_type': row['entity_type'],
          'entity_id': row['entity_id'],
          'action_type': row['action_type'],
          'action_payload': actionPayload,
          'created_at': row['created_at'],
          'resolved_at': row['resolved_at'],
        });
      })
      .where((a) => a.id.isNotEmpty)
      .toList();
}

Future<Map<String, dynamic>> _loadCachedProductMetricsReport(
  Ref ref,
  ProductMetricsQueryParams params,
) async {
  final db = await ref.read(localDatabaseProvider).database;
  final rows = await db.query('product_metrics');
  var items =
      rows
          .map(
            (row) => ProductMetricItem.fromJson({
              'product_id': row['product_id'],
              'product_name': row['product_name'],
              'stock_qty': row['stock_qty'],
              'cost_price': row['cost_price'],
              'qty_sold_7d': row['qty_sold_7d'],
              'qty_sold_30d': row['qty_sold_30d'],
              'revenue_30d': row['revenue_30d'],
              'profit_30d': row['profit_30d'],
              'last_sale_at': row['last_sale_at'],
              'dead_stock': (row['dead_stock'] as num?)?.toInt() == 1,
              'dead_stock_value': row['dead_stock_value'],
              'computed_at': row['computed_at'],
            }),
          )
          .where((p) => p.productId.isNotEmpty)
          .toList();

  if (params.deadStockOnly) {
    items = items.where((p) => p.deadStock).toList();
  }
  items = items.take(params.limit).toList();

  final deadStockItems = items.where((p) => p.deadStock).toList();
  final deadStockValueTotal = deadStockItems.fold<double>(
    0,
    (sum, p) => sum + (p.deadStockValue ?? 0),
  );
  final computedAt =
      rows.isEmpty
          ? null
          : rows
              .map((r) => r['computed_at']?.toString())
              .whereType<String>()
              .fold<String?>(
                null,
                (prev, next) =>
                    prev == null || next.compareTo(prev) > 0 ? next : prev,
              );
  return {
    'items': items,
    'total_products': rows.length,
    'dead_stock_count':
        rows.where((r) => (r['dead_stock'] as num?)?.toInt() == 1).length,
    'dead_stock_value_total': deadStockValueTotal,
    'computed_at': computedAt,
    'source': 'local_cache',
  };
}

Future<Map<String, dynamic>> _loadCachedBusinessMetrics(Ref ref) async {
  final db = await ref.read(localDatabaseProvider).database;
  final rows = await db.query(
    'business_metrics_cache',
    where: 'cache_key = ?',
    whereArgs: ['default'],
    limit: 1,
  );
  if (rows.isEmpty) return const {};
  final payloadJson = rows.first['payload_json']?.toString();
  if (payloadJson == null || payloadJson.isEmpty) return const {};
  try {
    final decoded = jsonDecode(payloadJson);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded)
        ..putIfAbsent('source', () => 'local_cache');
    }
  } catch (_) {}
  return const {};
}

double _rowToDouble(Object? v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

int _rowToInt(Object? v) =>
    v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

String _approxAgingFromOldestDue(int oldestDueDays, double outstanding) {
  if (outstanding <= 0) return 'd0_7';
  if (oldestDueDays <= 7) return 'd0_7';
  if (oldestDueDays <= 30) return 'd8_30';
  if (oldestDueDays <= 60) return 'd31_60';
  return 'd60_plus';
}
