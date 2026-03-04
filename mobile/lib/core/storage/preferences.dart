import 'package:shared_preferences/shared_preferences.dart';

import '../utils/uuid_id.dart';

class AppPreferences {
  static const _localeKey = 'locale_preference';
  static const _lastSyncKey = 'last_sync_at';
  static const _lastSyncCursorKey = 'last_sync_cursor';
  static const _deviceIdKey = 'device_id';
  static const _phoneKey = 'user_phone';
  static const _roleKey = 'user_role';
  static const _storeIdKey = 'active_store_id';
  static const _businessTimezoneKey = 'business_timezone';
  static const _calendarModeKey = 'calendar_mode';
  static const _alertReadIdsPrefix = 'alert_read_ids_';
  static const _setupPromptDismissedPrefix = 'setup_prompt_dismissed_';

  Future<String> getLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'ne';
  }

  Future<bool> hasLocalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_localeKey);
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

  Future<void> clearLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
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

  Future<String?> getActiveStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storeIdKey);
  }

  Future<void> setActiveStoreId(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeIdKey, storeId);
  }

  Future<void> clearActiveStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storeIdKey);
  }

  Future<String> getBusinessTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_businessTimezoneKey) ?? 'Asia/Kathmandu';
  }

  Future<void> setBusinessTimezone(String timezone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_businessTimezoneKey, timezone);
  }

  Future<String> getCalendarMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_calendarModeKey) ?? 'BS';
  }

  Future<void> setCalendarMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarModeKey, mode);
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

  Future<void> setBillingSettings({
    String? language,
    String? currencyCode,
    String? fiscalCalendar,
    bool? vatEnabled,
    double? vatRate,
    String? taxMode,
    String? invoicePrefix,
    String? invoiceTermsDefault,
    String? invoiceFooterDefault,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? panVatNumber,
    String? logoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (language != null) await prefs.setString('billing_language', language);
    if (currencyCode != null) {
      await prefs.setString('billing_currency_code', currencyCode);
    }
    if (fiscalCalendar != null) {
      await prefs.setString('billing_fiscal_calendar', fiscalCalendar);
    }
    if (vatEnabled != null)
      await prefs.setBool('billing_vat_enabled', vatEnabled);
    if (vatRate != null) await prefs.setDouble('billing_vat_rate', vatRate);
    if (taxMode != null) await prefs.setString('billing_tax_mode', taxMode);
    if (invoicePrefix != null) {
      await prefs.setString('billing_invoice_prefix', invoicePrefix);
    }
    if (invoiceTermsDefault != null) {
      await prefs.setString(
        'billing_invoice_terms_default',
        invoiceTermsDefault,
      );
    }
    if (invoiceFooterDefault != null) {
      await prefs.setString(
        'billing_invoice_footer_default',
        invoiceFooterDefault,
      );
    }
    if (businessName != null) {
      await prefs.setString('billing_business_name', businessName);
    }
    if (businessAddress != null) {
      await prefs.setString('billing_business_address', businessAddress);
    }
    if (businessPhone != null) {
      await prefs.setString('billing_business_phone', businessPhone);
    }
    if (businessEmail != null) {
      await prefs.setString('billing_business_email', businessEmail);
    }
    if (panVatNumber != null) {
      await prefs.setString('billing_pan_vat_number', panVatNumber);
    }
    if (logoPath != null) await prefs.setString('billing_logo_path', logoPath);
  }

  Future<Map<String, dynamic>> getBillingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final tax = await getTaxSettings();
    return {
      'language': prefs.getString('billing_language') ?? await getLocaleCode(),
      'currency_code': prefs.getString('billing_currency_code') ?? 'NPR',
      'fiscal_calendar':
          prefs.getString('billing_fiscal_calendar') ?? await getCalendarMode(),
      'vat_enabled':
          prefs.getBool('billing_vat_enabled') ?? (tax['enabled'] as bool),
      'vat_rate':
          prefs.getDouble('billing_vat_rate') ?? (tax['rate'] as double),
      'tax_mode': prefs.getString('billing_tax_mode') ?? 'exclusive',
      'invoice_prefix': prefs.getString('billing_invoice_prefix') ?? 'INV',
      'invoice_terms_default':
          prefs.getString('billing_invoice_terms_default') ?? '',
      'invoice_footer_default':
          prefs.getString('billing_invoice_footer_default') ?? '',
      'business_name': prefs.getString('billing_business_name') ?? 'Demo Store',
      'business_address': prefs.getString('billing_business_address') ?? '',
      'business_phone': prefs.getString('billing_business_phone') ?? '',
      'business_email': prefs.getString('billing_business_email') ?? '',
      'pan_vat_number': prefs.getString('billing_pan_vat_number') ?? '',
      'logo_path': prefs.getString('billing_logo_path'),
    };
  }

  String _alertReadIdsKey(String? storeId) =>
      '${_alertReadIdsPrefix}${(storeId == null || storeId.isEmpty) ? 'global' : storeId}';

  Future<Set<String>> getReadAlertIds({String? storeId}) async {
    final prefs = await SharedPreferences.getInstance();
    final ids =
        prefs.getStringList(_alertReadIdsKey(storeId)) ?? const <String>[];
    return ids.where((e) => e.isNotEmpty).toSet();
  }

  Future<void> markAlertRead(String alertId, {String? storeId}) async {
    if (alertId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _alertReadIdsKey(storeId);
    final ids = (prefs.getStringList(key) ?? const <String>[]).toSet();
    ids.add(alertId);
    await prefs.setStringList(key, ids.toList()..sort());
  }

  Future<void> markAlertsRead(
    Iterable<String> alertIds, {
    String? storeId,
  }) async {
    final clean = alertIds.where((e) => e.isNotEmpty).toSet();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _alertReadIdsKey(storeId);
    final ids = (prefs.getStringList(key) ?? const <String>[]).toSet();
    ids.addAll(clean);
    await prefs.setStringList(key, ids.toList()..sort());
  }

  Future<void> clearReadAlertIds({String? storeId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alertReadIdsKey(storeId));
  }

  String _dismissedSetupPromptKey(String promptId, String? storeId) =>
      '$_setupPromptDismissedPrefix${(storeId == null || storeId.isEmpty) ? 'global' : storeId}_$promptId';

  Future<bool> isSetupPromptDismissed(
    String promptId, {
    String? storeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dismissedSetupPromptKey(promptId, storeId)) ?? false;
  }

  Future<void> dismissSetupPrompt(
    String promptId, {
    String? storeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedSetupPromptKey(promptId, storeId), true);
  }

  Future<void> restoreSetupPrompt(
    String promptId, {
    String? storeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedSetupPromptKey(promptId, storeId));
  }
}
