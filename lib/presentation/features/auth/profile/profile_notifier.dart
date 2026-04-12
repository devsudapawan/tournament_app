// lib/presentation/features/auth/profile/profile_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/providers/providers.dart';

class ProfileState {
  final bool isLoading;
  final bool isSaved;
  final String? errorMessage;
  final Map<String, dynamic>? profileData;

  const ProfileState({
    this.isLoading   = false,
    this.isSaved     = false,
    this.errorMessage,
    this.profileData,
  });

  ProfileState copyWith({
    bool?                  isLoading,
    bool?                  isSaved,
    String?                errorMessage,
    Map<String, dynamic>?  profileData,
  }) =>
      ProfileState(
        isLoading:    isLoading    ?? this.isLoading,
        isSaved:      isSaved      ?? this.isSaved,
        errorMessage: errorMessage,
        profileData:  profileData  ?? this.profileData,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;
  ProfileNotifier(this._ref) : super(const ProfileState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final result = await _ref.read(getProfileUseCaseProvider).call();
    result.fold(
      (f) => state = state.copyWith(isLoading: false, errorMessage: f.message),
      (data) => state = state.copyWith(isLoading: false, profileData: data),
    );
  }

  Future<void> save(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(saveProfileUseCaseProvider).call(data);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, errorMessage: f.message),
      (_) => state = state.copyWith(isLoading: false, isSaved: true),
    );
  }
}

final profileNotifierProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref),
);
