// lib/presentation/common/providers/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/gemini_service_v2.dart';
import '../../../data/datasources/remote/supabase_datasource.dart';
import '../../../data/repositories/repository_impls.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../domain/usecases/use_cases.dart';

// ── Supabase ───────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// ── Data Sources ───────────────────────────────────────────
final supabaseDataSourceProvider = Provider<SupabaseDataSource>(
  (ref) => SupabaseDataSource(ref.watch(supabaseClientProvider)),
);

// ── Repositories ───────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(supabaseDataSourceProvider)),
);
final tournamentRepositoryProvider = Provider<TournamentRepository>(
  (ref) => TournamentRepositoryImpl(ref.watch(supabaseDataSourceProvider)),
);
final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepositoryImpl(ref.watch(supabaseDataSourceProvider)),
);
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => LeaderboardRepositoryImpl(ref.watch(supabaseDataSourceProvider)),
);

// ── Auth Use Cases ─────────────────────────────────────────
final signInUseCaseProvider = Provider(
  (ref) => SignInUseCase(ref.watch(authRepositoryProvider)),
);
final signUpUseCaseProvider = Provider(
  (ref) => SignUpUseCase(ref.watch(authRepositoryProvider)),
);
final signInWithGoogleUseCaseProvider = Provider(
  (ref) => SignInWithGoogleUseCase(ref.watch(authRepositoryProvider)),
);
final signInWithAppleUseCaseProvider = Provider(
  (ref) => SignInWithAppleUseCase(ref.watch(authRepositoryProvider)),
);
final signInWithFacebookUseCaseProvider = Provider(
  (ref) => SignInWithFacebookUseCase(ref.watch(authRepositoryProvider)),
);
final sendPasswordResetUseCaseProvider = Provider(
  (ref) => SendPasswordResetUseCase(ref.watch(authRepositoryProvider)),
);
final resendConfirmationUseCaseProvider = Provider(
  (ref) => ResendConfirmationUseCase(ref.watch(authRepositoryProvider)),
);
final signOutUseCaseProvider = Provider(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);
final getProfileUseCaseProvider = Provider(
  (ref) => GetProfileUseCase(ref.watch(authRepositoryProvider)),
);
final saveProfileUseCaseProvider = Provider(
  (ref) => SaveProfileUseCase(ref.watch(authRepositoryProvider)),
);

// ── Tournament Use Cases ───────────────────────────────────
final createTournamentUseCaseProvider = Provider(
  (ref) => CreateTournamentUseCase(ref.watch(tournamentRepositoryProvider)),
);
final getMyTournamentsUseCaseProvider = Provider(
  (ref) => GetMyTournamentsUseCase(ref.watch(tournamentRepositoryProvider)),
);
final getTournamentUseCaseProvider = Provider(
  (ref) => GetTournamentUseCase(ref.watch(tournamentRepositoryProvider)),
);
final saveTeamsUseCaseProvider = Provider(
  (ref) => SaveTeamsUseCase(ref.watch(tournamentRepositoryProvider)),
);
final getTeamsUseCaseProvider = Provider(
  (ref) => GetTeamsUseCase(ref.watch(tournamentRepositoryProvider)),
);

// ── Match Use Cases ────────────────────────────────────────
final createMatchesUseCaseProvider = Provider(
  (ref) => CreateMatchesUseCase(ref.watch(matchRepositoryProvider)),
);
final getMatchesUseCaseProvider = Provider(
  (ref) => GetMatchesUseCase(ref.watch(matchRepositoryProvider)),
);
final saveMatchResultUseCaseProvider = Provider(
  (ref) => SaveMatchResultUseCase(ref.watch(matchRepositoryProvider)),
);
final savePlayerKillsUseCaseProvider = Provider(
  (ref) => SavePlayerKillsUseCase(ref.watch(matchRepositoryProvider)),
);

// ── Leaderboard Use Cases ──────────────────────────────────
final getLeaderboardUseCaseProvider = Provider(
  (ref) => GetLeaderboardUseCase(ref.watch(leaderboardRepositoryProvider)),
);
final getMvpUseCaseProvider = Provider(
  (ref) => GetMvpUseCase(ref.watch(leaderboardRepositoryProvider)),
);
final getMatchBreakdownUseCaseProvider = Provider(
  (ref) => GetMatchBreakdownUseCase(ref.watch(leaderboardRepositoryProvider)),
);
final leaderboardStreamUseCaseProvider = Provider(
  (ref) => LeaderboardStreamUseCase(ref.watch(leaderboardRepositoryProvider)),
);

// ── AI Service — replaces ocrServiceProvider ──────────────
final geminiServiceProvider = Provider<GeminiService>((_) => GeminiService());

// ── Auth State Stream ──────────────────────────────────────
final authStateProvider = StreamProvider<User?>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange
      .map((e) => e.session?.user),
);
