class AuthState {
  AuthState({
    this.loading = false,
    this.authenticated = false,
    this.error,
    this.phone,
    this.role,
    this.otpRequested = false,
    this.pendingPhone,
    this.debugOtpCode,
  });

  final bool loading;
  final bool authenticated;
  final String? error;
  final String? phone;
  final String? role;
  final bool otpRequested;
  final String? pendingPhone;
  final String? debugOtpCode;

  String get effectiveRole {
    final raw = role?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return 'owner';
    // Be tolerant to legacy/backend aliases so owner-capable users are not blocked.
    if (raw == 'admin' || raw == 'superadmin' || raw == 'super_admin') {
      return 'owner';
    }
    return raw;
  }

  bool get isOwner => effectiveRole == 'owner';
  bool get canAdjustStock =>
      effectiveRole == 'owner' || effectiveRole == 'staff';
  bool get canManageSettings => effectiveRole == 'owner';
  bool get canManageUsers => effectiveRole == 'owner';

  static const _unset = Object();

  AuthState copyWith({
    bool? loading,
    bool? authenticated,
    Object? error = _unset,
    Object? phone = _unset,
    Object? role = _unset,
    bool? otpRequested,
    Object? pendingPhone = _unset,
    Object? debugOtpCode = _unset,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      authenticated: authenticated ?? this.authenticated,
      error: identical(error, _unset) ? this.error : error as String?,
      phone: identical(phone, _unset) ? this.phone : phone as String?,
      role: identical(role, _unset) ? this.role : role as String?,
      otpRequested: otpRequested ?? this.otpRequested,
      pendingPhone: identical(pendingPhone, _unset)
          ? this.pendingPhone
          : pendingPhone as String?,
      debugOtpCode: identical(debugOtpCode, _unset)
          ? this.debugOtpCode
          : debugOtpCode as String?,
    );
  }
}
