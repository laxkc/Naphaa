import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import 'app_providers.dart';

final currentAuthStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authControllerProvider);
});

final currentUserRoleProvider = Provider<String>((ref) {
  return ref.watch(currentAuthStateProvider).effectiveRole;
});

final canManageSettingsProvider = Provider<bool>((ref) {
  return ref.watch(currentAuthStateProvider).canManageSettings;
});

final canAdjustStockProvider = Provider<bool>((ref) {
  return ref.watch(currentAuthStateProvider).canAdjustStock;
});

final canManageUsersProvider = Provider<bool>((ref) {
  return ref.watch(currentAuthStateProvider).canManageUsers;
});

