import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/customers/data/customers_repository.dart';
import '../../features/customers/domain/customer.dart';
import '../../features/expenses/data/expenses_repository.dart';
import '../../features/expenses/domain/expense.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/products/data/products_repository.dart';
import '../../features/products/domain/product.dart';
import '../../features/products/domain/stock_movement.dart';
import '../../features/sales/data/sales_repository.dart';
import '../../features/sales/domain/sale.dart';
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

final localDatabaseProvider = Provider<LocalDatabase>(
  (ref) => LocalDatabase.instance,
);

final preferencesProvider = Provider<AppPreferences>((ref) => AppPreferences());

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
      if (token != null && token.isNotEmpty) {
        state = state.copyWith(authenticated: true, phone: phone, error: null);
      }
    });
    return AuthState();
  }

  Future<void> login({required String phone, required String password}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final locale = ref.read(localeControllerProvider).languageCode;
      await _session.login(
        phone: phone,
        password: password,
        localeCode: locale,
      );
      await _prefs.setUserPhone(phone);
      state = state.copyWith(
        loading: false,
        authenticated: true,
        phone: phone,
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
      final locale = ref.read(localeControllerProvider).languageCode;
      await _session.signup(
        businessName: businessName,
        phone: phone,
        password: password,
        localeCode: locale,
      );
      await _prefs.setUserPhone(phone);
      state = state.copyWith(
        loading: false,
        authenticated: true,
        phone: phone,
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
    await _prefs.clearUserPhone();
    state = AuthState();
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

typedef ConnectivityCheckFn = Future<List<ConnectivityResult>> Function({
  Connectivity? connectivity,
});

typedef ConnectivityChangesFn = Stream<List<ConnectivityResult>> Function({
  Connectivity? connectivity,
});

final syncConnectivityCheckProvider =
    Provider<ConnectivityCheckFn>((ref) {
  return ({Connectivity? connectivity}) {
    final c = connectivity ?? Connectivity();
    return c.checkConnectivity();
  };
});

final syncConnectivityChangesProvider =
    Provider<ConnectivityChangesFn>((ref) {
  return ({Connectivity? connectivity}) {
    final c = connectivity ?? Connectivity();
    return c.onConnectivityChanged;
  };
});

final syncCoordinatorDebounceDurationProvider =
    Provider<Duration>((ref) => const Duration(seconds: 2));

final syncCoordinatorPeriodicDurationProvider =
    Provider<Duration>((ref) => const Duration(seconds: 30));

class SyncStatusState {
  const SyncStatusState({
    this.online = true,
    this.syncing = false,
    this.pendingCount = 0,
    this.lastSuccessAt,
    this.lastError,
  });

  final bool online;
  final bool syncing;
  final int pendingCount;
  final DateTime? lastSuccessAt;
  final String? lastError;

  SyncStatusState copyWith({
    bool? online,
    bool? syncing,
    int? pendingCount,
    DateTime? lastSuccessAt,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncStatusState(
      online: online ?? this.online,
      syncing: syncing ?? this.syncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class SyncCoordinatorController extends Notifier<SyncStatusState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;
  Timer? _debounceTimer;
  bool _inFlight = false;
  bool _started = false;
  int _failureCount = 0;
  DateTime? _backoffUntil;

  @override
  SyncStatusState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _periodicTimer?.cancel();
      _connectivitySub?.cancel();
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
    final initial = await ref
        .read(syncConnectivityCheckProvider)(connectivity: connectivity);
    if (!ref.mounted) return;
    final initialOnline = initial.any((it) => it != ConnectivityResult.none);
    state = state.copyWith(online: initialOnline);

    _connectivitySub = ref
        .read(syncConnectivityChangesProvider)(connectivity: connectivity)
        .listen((results) {
      final online = results.any((it) => it != ConnectivityResult.none);
      state = state.copyWith(online: online);
      if (online) {
        _scheduleSyncDebounced();
      }
    });

    _periodicTimer = Timer.periodic(
      ref.read(syncCoordinatorPeriodicDurationProvider),
      (_) {
      _triggerSync();
      },
    );

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
      final syncResult = await ref
          .read(syncManagerProvider)
          .processPendingSyncDetailed(localeCode: localeCode);
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
        clearError: !syncResult.hasFailures,
      );

      // Refresh common local-first UI sources after sync updates local DB.
      ref.invalidate(productsListProvider);
      ref.invalidate(customersListProvider);
      ref.invalidate(expensesListProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(creditReportProvider);
      ref.invalidate(salesReportProvider);
    } catch (e) {
      await _refreshPendingCount();
      if (!ref.mounted) return;
      final msg = e.toString();
      _failureCount += 1;
      final backoffSeconds = _computeBackoffSeconds(_failureCount);
      _backoffUntil = DateTime.now().add(Duration(seconds: backoffSeconds));
      state = state.copyWith(
        syncing: false,
        lastError: msg.length > 300 ? msg.substring(0, 300) : msg,
      );
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _refreshPendingCount() async {
    if (!ref.mounted) return;
    final db = await ref.read(localDatabaseProvider).database;
    if (!ref.mounted) return;
    final row = await db.rawQuery(
      """
      SELECT COUNT(*) AS total
      FROM sync_queue
      WHERE synced = 0
        AND COALESCE(status, 'pending') IN ('pending', 'failed')
      """,
    );
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
  (ref) => ProductsRepository(ref.watch(localDatabaseProvider)),
);

final customersRepositoryProvider = Provider<CustomersRepository>(
  (ref) => CustomersRepository(ref.watch(localDatabaseProvider)),
);

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepository(ref.watch(localDatabaseProvider)),
);

final productsListProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(productsRepositoryProvider).listProducts(),
);

final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final products = await ref.watch(productsListProvider.future);
  return products
      .where(
        (p) =>
            p.lowStockThreshold > 0 && p.stockQty <= p.lowStockThreshold,
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
  (ref) => SalesRepository(ref.watch(localDatabaseProvider)),
);

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
  final auth = ref.watch(authControllerProvider);
  if (!auth.authenticated) return;
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
  String? storeName;
  String? localeDefault;
  try {
    final locale = ref.watch(localeControllerProvider).languageCode;
    await ref.watch(sessionServiceProvider).ensureReady(localeCode: locale);
    final gateway = ref.watch(backendGatewayProvider);

    // Prefer /auth/me because it includes user + store snapshot together.
    final profile = await gateway.getAuthMe();
    storeName = profile['store_name']?.toString();
    localeDefault = profile['locale_default']?.toString();

    final missingStoreName = (storeName?.trim().isEmpty ?? true);
    final missingLocaleDefault = (localeDefault?.trim().isEmpty ?? true);
    if (missingStoreName || missingLocaleDefault) {
      final store = await gateway.getStoreMe();
      storeName =
          storeName?.trim().isNotEmpty == true
              ? storeName
              : store['name']?.toString();
      localeDefault =
          localeDefault?.trim().isNotEmpty == true
              ? localeDefault
              : store['locale_default']?.toString();
    }
  } catch (_) {
    // Offline or unauthenticated fallback
  }
  return ProfileData(
    phone: phone,
    storeName: storeName,
    localeDefault: localeDefault,
  );
});

// ─── Sales list & detail providers ───────────────────────────────────────────

class SalesListParams {
  const SalesListParams({
    this.fromDate,
    this.toDate,
    this.customerId,
  });

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

final saleDetailProvider =
    FutureProvider.autoDispose.family<Sale?, String>((ref, id) {
  return ref.watch(salesRepositoryProvider).getSaleById(id);
});

// ─── Product detail providers ─────────────────────────────────────────────────

final productDetailProvider =
    FutureProvider.autoDispose.family<Product?, String>((ref, id) {
  return ref.watch(productsRepositoryProvider).getProductById(id);
});

final stockMovementsProvider =
    FutureProvider.autoDispose.family<List<StockMovement>, String>(
        (ref, productId) {
  return ref.watch(productsRepositoryProvider).getStockMovements(productId);
});

// ─── Customer detail providers ────────────────────────────────────────────────

final customerDetailProvider =
    FutureProvider.autoDispose.family<Customer?, String>((ref, id) {
  return ref.watch(customersRepositoryProvider).getCustomerById(id);
});

final customerLedgerProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, customerId) {
  return ref
      .watch(customersRepositoryProvider)
      .getCustomerLedger(customerId);
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

final salesReportProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, ReportParams>(
        (ref, params) async {
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

final creditReportProvider =
    FutureProvider.autoDispose<List<Customer>>((ref) async {
  final customers =
      await ref.watch(customersRepositoryProvider).listCustomers();
  return customers
      .where((c) => c.balance > 0)
      .toList()
    ..sort((a, b) => b.balance.compareTo(a.balance));
});
