import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/index.dart';

// Hardcoded credentials (replace with real API later)
const _kValidEmail    = 'user@test.com';
const _kValidPassword = 'password123';

// ── Auth State ───────────────────────────────────────────────────────────────

enum AuthStatus { idle, loading, authenticated, error }

class AuthState {
  const AuthState({
    this.status  = AuthStatus.idle,
    this.errorMsg,
  });

  final AuthStatus status;
  final String?    errorMsg;

  bool get isLoading       => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, String? errorMsg}) => AuthState(
        status:   status   ?? this.status,
        errorMsg: errorMsg ?? this.errorMsg,
      );
}

// ── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Attempt login with [email] and [password].
  /// Returns true on success.
  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMsg: null);

    // Simulate a brief async check (swap with real API call later)
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedEmail == _kValidEmail && password == _kValidPassword) {
      // Persist session via centralized service
      await HiveService.saveLoginState(true);

      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
    } else {
      state = state.copyWith(
        status:   AuthStatus.error,
        errorMsg: 'Invalid email or password.',
      );
      return false;
    }
  }

  /// Clear session and return to unauthenticated state.
  Future<void> logout() async {
    await HiveService.saveLoginState(false);
    state = const AuthState();
  }

  /// Reset error so the form can be re-submitted cleanly.
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthState();
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// Session check helper was removed; main.dart now calls HiveService.getLoginState() directly.
