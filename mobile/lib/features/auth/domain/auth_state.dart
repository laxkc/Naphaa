class AuthState {
  AuthState({
    this.loading = false,
    this.authenticated = false,
    this.error,
    this.phone,
  });

  final bool loading;
  final bool authenticated;
  final String? error;
  final String? phone;

  AuthState copyWith({
    bool? loading,
    bool? authenticated,
    String? error,
    String? phone,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      authenticated: authenticated ?? this.authenticated,
      error: error ?? this.error,
      phone: phone ?? this.phone,
    );
  }
}
