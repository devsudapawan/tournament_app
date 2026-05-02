//
//
// class AppConstants {
//   AppConstants._();
//
//   // ── Supabase ──────────────────────────────────
//   static const supabaseUrl     = 'https://fwjjsxbcrowjgxiizung.supabase.co';
//   static const supabaseAnonKey = 'sb_publishable_LHwRi40hYKv8mtgEptRd-Q_iXYlB_HU';
//   static const geminiApiKey     = 'AIzaSyB_Jivigx_L2WJQ7Glhlsrbu0PvD3AfnbM';
//   static const geminiFlashLite = 'gemini-flash-lite-latest';
//   static const geminiFlash     = 'gemini-flash-latest';
//

//   // ── Tournament Rules ──────────────────────────
//   static const minMatches       = 3;
//   static const maxMatches       = 8;
//   static const maxTeamSlots     = 24;
//   static const maxLobbyImages   = 3;
//   static const minResultImages  = 6;
//   static const maxResultImages  = 8;
//   static const mvpCount         = 5;
//
//   // ── Default Point System ──────────────────────
//   static const defaultRankPoints = {
//     1: 10, 2: 8, 3: 6, 4: 4,
//     5:  3, 6: 2, 7: 1, 8: 1,
//   };
//   static const defaultKillPoints  = 1;
//
//   // ── Matching ──────────────────────────────────
//   static const fuzzyMatchThreshold = 0.75;
// }
//
// class AppStrings {
//   AppStrings._();
//   static const appName = 'PointCalc';
//   static const tagline = 'Automate your tournament';
// }
//
// class AppAssets {
//   AppAssets._();
//   static const logo     = 'assets/images/logo.png';
//   static const bgmiIcon = 'assets/icons/bgmi.png';
// }

// lib/core/constants/app_constants.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // ── Supabase ──────────────────────────────────
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get newsApiKey => dotenv.env['NEWS_API_KEY'] ?? '';

  // ── Gemini Model Names (corrected) ───────────
  // gemini-2.0-flash-lite → fast, very high text quota, used first
  // gemini-2.0-flash      → fallback when lite fails
  static const geminiFlashLite = 'gemini-flash-lite-latest';
  static const geminiFlash = 'gemini-flash-latest';

  // Change these two lines:
  // static const geminiFlashLite = 'gemini-2.0-flash-lite';
  // static const geminiFlash     = 'gemini-2.0-flash';
  //
  // static const geminiFlashLite = 'gemini-2.0-flash-lite';
  // static const geminiFlash     = 'gemini-2.0-flash';

  // ── Tournament Rules ──────────────────────────
  static const minMatches = 3;
  static const maxMatches = 8;
  static const maxTeamSlots = 24;
  static const maxLobbyImages = 3;
  static const minResultImages = 6;
  static const maxResultImages = 8;
  static const mvpCount = 5;

  // ── Default Point System ──────────────────────
  static const defaultRankPoints = {
    1: 10,
    2: 8,
    3: 6,
    4: 4,
    5: 3,
    6: 2,
    7: 1,
    8: 1,
  };
  static const defaultKillPoints = 1;

  // ── Matching ──────────────────────────────────
  static const fuzzyMatchThreshold = 0.75;

  // ── OCR ───────────────────────────────────────
  // Minimum characters ML Kit must extract for the text to be
  // considered usable. Below this → fall back to Gemini vision.
  static const minOcrTextLength = 30;
}

class AppStrings {
  AppStrings._();
  static const appName = 'PointCalc';
  static const tagline = 'Automate your tournament';
}

class AppAssets {
  AppAssets._();
  static const logo = 'assets/images/logo.png';
  static const bgmiIcon = 'assets/icons/bgmi.png';
}
