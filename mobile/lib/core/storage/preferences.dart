import 'package:shared_preferences/shared_preferences.dart';

import '../utils/uuid_id.dart';

class AppPreferences {
  static const _localeKey = 'locale_preference';
  static const _lastSyncKey = 'last_sync_at';
  static const _lastSyncCursorKey = 'last_sync_cursor';
  static const _deviceIdKey = 'device_id';
  static const _phoneKey = 'user_phone';
  static const _roleKey = 'user_role';

  Future<String> getLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'ne';
  }

  Future<void> setLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);
  }

  Future<String?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }

  Future<void> setLastSyncAt(String iso) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, iso);
  }

  Future<String?> getLastSyncCursor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncCursorKey);
  }

  Future<void> setLastSyncCursor(String cursor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncCursorKey, cursor);
  }

  Future<void> clearLastSyncCursor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncCursorKey);
  }

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = newUuidV4();
    await prefs.setString(_deviceIdKey, created);
    return created;
  }

  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  Future<void> setUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, phone);
  }

  Future<void> clearUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneKey);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }

  Future<bool> getOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  Future<void> setTaxSettings({
    required bool enabled,
    required String name,
    required double rate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tax_enabled', enabled);
    await prefs.setString('tax_name', name);
    await prefs.setDouble('tax_rate', rate);
  }

  Future<Map<String, dynamic>> getTaxSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('tax_enabled') ?? false,
      'name': prefs.getString('tax_name') ?? 'VAT',
      'rate': prefs.getDouble('tax_rate') ?? 13.0,
    };
  }
}
