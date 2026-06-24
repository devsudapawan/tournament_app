// lib/presentation/features/auth/register/register_notifier.dart

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/providers/providers.dart';

class RegisterState {
  final bool isLoading;
  final bool isSocialLoading;
  final String? errorMessage;
  final bool success;
  final bool requiresEmailConfirmation;

  const RegisterState({
    this.isLoading                 = false,
    this.isSocialLoading           = false,
    this.errorMessage,
    this.success                   = false,
    this.requiresEmailConfirmation = false,
  });

  RegisterState copyWith({
    bool?   isLoading,
    bool?   isSocialLoading,
    String? errorMessage,
    bool?   success,
    bool?   requiresEmailConfirmation,
  }) =>
      RegisterState(
        isLoading:                 isLoading                 ?? this.isLoading,
        isSocialLoading:           isSocialLoading           ?? this.isSocialLoading,
        errorMessage:              errorMessage,
        success:                   success                   ?? this.success,
        requiresEmailConfirmation: requiresEmailConfirmation ?? this.requiresEmailConfirmation,
      );
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  final Ref _ref;
  RegisterNotifier(this._ref) : super(const RegisterState());

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    int? age,
    String? gender,
    String? phone,
    File? profileImage,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result =
    await _ref.read(signUpUseCaseProvider).call(email, password);

    result.fold(
          (f) => state = state.copyWith(
          isLoading: false, errorMessage: f.message),
          (requiresConfirmation) => state = state.copyWith(
        isLoading:                 false,
        success:                   true,
        requiresEmailConfirmation: requiresConfirmation,
      ),
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
}

final registerNotifierProvider =
StateNotifierProvider.autoDispose<RegisterNotifier, RegisterState>(
      (ref) => RegisterNotifier(ref),
);