class AuthState {
  AuthState({
    this.loading = false,
    this.authenticated = false,
    this.error,
    this.phone,
    this.role,
  });

  final bool loading;
  final bool authenticated;
  final String? error;
  final String? phone;
  final String? role;

  String get effectiveRole => (role == null || role!.isEmpty) ? 'owner' : role!;
  bool get isOwner => effectiveRole == 'owner';
  bool get canAdjustStock => effectiveRole == 'owner' || effectiveRole == 'staff';
  bool get canManageSettings => effectiveRole == 'owner';
  bool get canManageUsers => effectiveRole == 'owner';

  AuthState copyWith({
    bool? loading,
    bool? authenticated,
    String? error,
    String? phone,
    String? role,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      authenticated: authenticated ?? this.authenticated,
      error: error ?? this.error,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }
}
