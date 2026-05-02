
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tournament_app/presentation/features/auth/profile/profile_screen.dart';
import 'package:tournament_app/presentation/features/home/home_screen.dart';
import '../../presentation/common/providers/auth_state_provider.dart';
import '../../presentation/features/dashboard/dashboard_screen.dart';
import '../../presentation/features/news/news_screen.dart';
import '../../presentation/features/shell/main_shell.dart';
import '../../presentation/features/splash/splash_screen.dart';
import '../../presentation/features/auth/login/login_screen.dart';
import '../../presentation/features/auth/register/register_screen.dart';
import '../../presentation/features/tournament/create/create_tournament_screen.dart';
import '../../presentation/features/tournament/detail/tournament_detail_screen.dart';
import '../../presentation/features/match/detail/match_detail_screen.dart';
import '../../presentation/features/match/upload/upload_screen.dart';
import '../../presentation/features/match/verify/verify_screen.dart';
import '../../presentation/features/leaderboard/screens/leaderboard_screen.dart';
import '../../presentation/features/tournament_list/tournament_list.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;

      final isLoggingIn = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;

      if (isGoingToSplash) return null;

      /// NOT logged in → force login
      if (!isLoggedIn) {
        return isLoggingIn ? null : AppRoutes.login;
      }

      /// logged in → prevent returning to login/register
      if (isLoggingIn) {
        return AppRoutes.shell;
      }

      return null;
    },
    routes: [
      // ── Unauthenticated ──────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Full-screen routes OUTSIDE shell (no bottom nav) ──
      GoRoute(
        path: AppRoutes.createTournament,
        builder: (_, __) => const CreateTournamentScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.tournamentDetail}/:tournamentId',
        builder: (_, state) => TournamentDetailScreen(
          tournamentId: state.pathParameters['tournamentId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.matchDetail}/:tournamentId/:matchId',
        builder: (_, state) => MatchDetailScreen(
          tournamentId: state.pathParameters['tournamentId']!,
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.upload}/:tournamentId/:matchId/:type',
        builder: (_, state) => UploadScreen(
          tournamentId: state.pathParameters['tournamentId']!,
          matchId: state.pathParameters['matchId']!,
          uploadType: state.pathParameters['type']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.verify}/:tournamentId/:matchId/:type',
        builder: (_, state) => VerifyScreen(
          tournamentId: state.pathParameters['tournamentId']!,
          matchId: state.pathParameters['matchId']!,
          uploadType: state.pathParameters['type']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.leaderboard}/:tournamentId',
        builder: (_, state) => LeaderboardScreen(
          tournamentId: state.pathParameters['tournamentId']!,
        ),
      ),

      GoRoute(
        path: AppRoutes.newsDetailPage,
        builder: (_, state) => NewsDetailPage(
          news: state.extra,
        ),
      ),

      // ── Main app shell with bottom nav ───────────
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.tournamentDetail,
            builder: (_, __) => const TournamentListScreen(),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Text('Error: ${state.error}',
            style: const TextStyle(color: Colors.white)),
      ),
    ),
  );
}

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const shell = '/home';
  static const dashboard = '/dashboard';
  static const createTournament = '/tournament/create';
  static const tournamentDetail = '/tournamentDetail';
  static const matchDetail = '/matchDetail';
  static const upload = '/upload';
  static const profile = '/profile';
  static const verify = '/verify';
  static const home = '/home';
  static const leaderboard = '/leaderboard';
  static const newsDetailPage = '/newsDetailPage';
}