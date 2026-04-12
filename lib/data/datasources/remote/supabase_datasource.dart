// lib/data/datasources/remote/supabase_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/exceptions.dart' hide AuthException;
import '../../models/models.dart';

class SupabaseDataSource {
  final SupabaseClient _client;
  SupabaseDataSource(this._client);

  String get _uid =>
      _client.auth.currentUser?.id ?? (throw const AuthException('Not logged in'));

  // ── Auth ───────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email:    email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw const AuthException('Unexpected error. Please try again.');
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      final res = await _client.auth.signUp(
        email:    email,
        password: password,
      );
      // Returns true if email confirmation is required
      // Returns false if user is immediately confirmed (email confirm disabled)
      return res.session == null && res.user != null;
    } on AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw const AuthException('Unexpected error. Please try again.');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.tournamentapp://login-callback',
      );
    } on AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw const AuthException('Google sign-in failed. Please try again.');
    }
  }

  Future<void> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.tournamentapp://login-callback',
      );
    } on AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw const AuthException('Apple sign-in failed. Please try again.');
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.tournamentapp://login-callback',
      );
    } on AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw const AuthException('Facebook sign-in failed. Please try again.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.tournamentapp://reset-password',
      );
    } on AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw const AuthException('Could not send reset email. Please try again.');
    }
  }

  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _client.auth.resend(
        type:  OtpType.signup,
        email: email,
      );
    } on AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw const AuthException('Could not resend email. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Ignore sign out errors
    }
  }

  User? get currentUser => _client.auth.currentUser;

  // ── Error mapper ───────────────────────────────────────────
  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('email not confirmed')) {
      return 'email_not_confirmed';
    }
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password')) {
      return 'Wrong email or password. Please try again.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('unable to validate email address')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('email rate limit exceeded')) {
      return 'Too many attempts. Please wait a few minutes.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    return e.message;
  }

  // ── Profile ────────────────────────────────────────────────

  Future<void> upsertProfile(Map<String, dynamic> data) async {
    try {
      await _client.from('profiles').upsert({...data, 'id': _uid});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      return await _client
          .from('profiles')
          .select()
          .eq('id', _uid)
          .maybeSingle();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Tournaments ────────────────────────────────────────────

  Future<TournamentModel> createTournament(Map<String, dynamic> data) async {
    try {
      final res = await _client
          .from('tournaments')
          .insert({...data, 'user_id': _uid})
          .select()
          .single();
      return TournamentModel.fromMap(res);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<TournamentModel>> getMyTournaments() async {
    try {
      final res = await _client
          .from('tournaments')
          .select()
          .eq('user_id', _uid)
          .order('created_at', ascending: false);
      return (res as List).map((m) => TournamentModel.fromMap(m)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<TournamentModel?> getTournament(String id) async {
    try {
      final res = await _client
          .from('tournaments')
          .select()
          .eq('id', id)
          .maybeSingle();
      return res != null ? TournamentModel.fromMap(res) : null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> updateTournamentStatus(String id, String status) async {
    try {
      await _client
          .from('tournaments')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Teams ──────────────────────────────────────────────────

  Future<List<TeamModel>> insertTeams(List<Map<String, dynamic>> teams) async {
    try {
      final res = await _client.from('teams').insert(teams).select();
      return (res as List).map((m) => TeamModel.fromMap(m)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<TeamModel>> getTeams(String tournamentId) async {
    try {
      final res = await _client
          .from('teams')
          .select('*, players(*)')
          .eq('tournament_id', tournamentId)
          .order('slot_number');
      return (res as List).map((m) => TeamModel.fromMap(m)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Players ────────────────────────────────────────────────

  Future<void> upsertPlayers(List<Map<String, dynamic>> players) async {
    try {
      await _client.from('players').upsert(players);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Matches ────────────────────────────────────────────────

  Future<void> insertMatches(List<Map<String, dynamic>> matches) async {
    try {
      await _client.from('matches').insert(matches);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<MatchModel>> getMatches(String tournamentId) async {
    try {
      final res = await _client
          .from('matches')
          .select()
          .eq('tournament_id', tournamentId)
          .order('match_number');
      return (res as List).map((m) => MatchModel.fromMap(m)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    try {
      await _client
          .from('matches')
          .update({'status': status})
          .eq('id', matchId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Match Results ──────────────────────────────────────────

  Future<void> saveMatchResult(Map<String, dynamic> params) async {
    try {
      await _client.rpc(
        'calculate_and_insert_match_result',
        params: params,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> savePlayerKills(Map<String, dynamic> data) async {
    try {
      await _client.from('player_match_kills').upsert(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ── Leaderboard ────────────────────────────────────────────

  Future<List<LeaderboardModel>> getLeaderboard(String tournamentId) async {
    try {
      final res = await _client
          .from('tournament_leaderboard')
          .select()
          .eq('tournament_id', tournamentId)
          .order('position');
      return (res as List).map((m) => LeaderboardModel.fromMap(m)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<MvpModel>> getMvp(String tournamentId) async {
    try {
      final res = await _client
          .from('tournament_mvp')
          .select()
          .eq('tournament_id', tournamentId)
          .lte('mvp_rank', 5)
          .order('mvp_rank');
      return (res as List).map((m) => MvpModel.fromMap(m)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getMatchBreakdown(
      String tournamentId) async {
    try {
      final res = await _client.rpc(
        'get_match_breakdown',
        params: {'p_tournament_id': tournamentId},
      );
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Stream<List<LeaderboardModel>> leaderboardStream(String tournamentId) =>
      _client
          .from('match_results')
          .stream(primaryKey: ['id'])
          .eq('tournament_id', tournamentId)
          .asyncMap((_) => getLeaderboard(tournamentId));
}