// lib/data/datasources/local/local_datasource.dart
//
// Handles local persistence using SharedPreferences.
// Used to cache user session, last-viewed tournament, etc.

import 'package:shared_preferences/shared_preferences.dart';

class LocalDataSource {
  static const _keyUserId          = 'user_id';
  static const _keyLastTournament  = 'last_tournament_id';
  static const _keyOnboardingDone  = 'onboarding_done';

  // ── User ─────────────────────────────────────────────────
  Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, id);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }

  // ── Last Tournament ───────────────────────────────────────
  Future<void> saveLastTournament(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastTournament, id);
  }

  Future<String?> getLastTournament() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastTournament);
  }

  // ── Onboarding ────────────────────────────────────────────
  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  // ── Clear All ─────────────────────────────────────────────
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
