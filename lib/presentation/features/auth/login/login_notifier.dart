// lib/presentation/features/auth/login/login_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/providers/providers.dart';

// ── State ──────────────────────────────────────────────────
class LoginState {
  final bool isLoading;
  final bool isSocialLoading;
  final String? errorMessage;
  final bool success;
  final bool emailNotConfirmed;
  final String? unconfirmedEmail;

  const LoginState({
    this.isLoading          = false,
    this.isSocialLoading    = false,
    this.errorMessage,
    this.success            = false,
    this.emailNotConfirmed  = false,
    this.unconfirmedEmail,
  });

  LoginState copyWith({
    bool?   isLoading,
    bool?   isSocialLoading,
    String? errorMessage,
    bool?   success,
    bool?   emailNotConfirmed,
    String? unconfirmedEmail,
  }) =>
      LoginState(
        isLoading:         isLoading         ?? this.isLoading,
        isSocialLoading:   isSocialLoading   ?? this.isSocialLoading,
        errorMessage:      errorMessage,
        success:           success           ?? this.success,
        emailNotConfirmed: emailNotConfirmed ?? this.emailNotConfirmed,
        unconfirmedEmail:  unconfirmedEmail  ?? this.unconfirmedEmail,
      );
}

// ── Notifier ───────────────────────────────────────────────
class LoginNotifier extends StateNotifier<LoginState> {
  final Ref _ref;
  LoginNotifier(this._ref) : super(const LoginState());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null,
        emailNotConfirmed: false);

    final result =
    await _ref.read(signInUseCaseProvider).call(email, password);

    result.fold(
          (failure) {
        // Special handling for unconfirmed email
        if (failure.message == 'email_not_confirmed') {
          state = state.copyWith(
            isLoading:         false,
            emailNotConfirmed: true,
            unconfirmedEmail:  email,
          );
        } else {
          state = state.copyWith(
            isLoading:    false,
            errorMessage: failure.message,
          );
        }
      },
          (_) => state = state.copyWith(isLoading: false, success: true),
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isSocialLoading: true, errorMessage: null);
    final result = await _ref.read(signInWithGoogleUseCaseProvider).call();
    result.fold(
          (f) => state = state.copyWith(
          isSocialLoading: false, errorMessage: f.message),
          (_) => state = state.copyWith(isSocialLoading: false, success: true),
    );
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isSocialLoading: true, errorMessage: null);
    final result = await _ref.read(signInWithAppleUseCaseProvider).call();
    result.fold(
          (f) => state = state.copyWith(
          isSocialLoading: false, errorMessage: f.message),
          (_) => state = state.copyWith(isSocialLoading: false, success: true),
    );
  }

  Future<void> signInWithFacebook() async {
    state = state.copyWith(isSocialLoading: true, errorMessage: null);
    final result = await _ref.read(signInWithFacebookUseCaseProvider).call();
    result.fold(
          (f) => state = state.copyWith(
          isSocialLoading: false, errorMessage: f.message),
          (_) => state = state.copyWith(isSocialLoading: false, success: true),
    );
  }

  Future<void> resendConfirmation(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result =
    await _ref.read(resendConfirmationUseCaseProvider).call(email);
    result.fold(
          (f) => state = state.copyWith(
          isLoading: false, errorMessage: f.message),
          (_) => state = state.copyWith(
        isLoading:    false,
        errorMessage: null,
        // Keep emailNotConfirmed true — user still needs to confirm
      ),
    );
  }

  void clearError() => state = state.copyWith(errorMessage: null);
  void clearEmailNotConfirmed() =>
      state = state.copyWith(emailNotConfirmed: false);
}

// ── Provider ───────────────────────────────────────────────
final loginNotifierProvider =
StateNotifierProvider.autoDispose<LoginNotifier, LoginState>(
      (ref) => LoginNotifier(ref),
);