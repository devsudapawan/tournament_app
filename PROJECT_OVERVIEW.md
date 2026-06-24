# PointCalc Project Overview

PointCalc is an Esports Tournament Manager application designed to automate leaderboard calculations for BGMI (Battlegrounds Mobile India) matches. It uses a combination of local OCR (Optical Character Recognition) and cloud-based Gemini Generative AI to parse game screenshots (lobby lists and result standings), match players to their slots using fuzzy string similarity, and generate dynamic point tables and MVP stats. The app's backend is powered by Supabase.

---

## 🏗️ Architecture & Tech Stack

The project is structured following **Clean Architecture** principles (Data, Domain, and Presentation layers) paired with **Riverpod** for reactive state management and **GoRouter** for application routing.

*   **Frontend**: Flutter (Dart)
*   **Database & Auth**: Supabase (Postgres, Row Level Security, Auth, RPC functions)
*   **OCR**: On-device [Google ML Kit Text Recognition](https://pub.dev/packages/google_ml_kit_text_recognition)
*   **AI Engine**: [Google Generative AI SDK](https://pub.dev/packages/google_generative_ai) (Gemini 2.0 Flash Lite & Gemini 2.0 Flash)
*   **Routing**: [GoRouter](https://pub.dev/packages/go_router)
*   **State Management**: [Riverpod (with code generation)](https://pub.dev/packages/flutter_riverpod)

### Directory Structure

```text
lib/
├── core/                  # Shared utilities, constants, routing, and themes
│   ├── constants/         # App constants & strings
│   ├── network/           # Network state utilities
│   ├── router/            # GoRouter configurations
│   ├── theme/             # Global dark theme definitions
│   └── utils/             # Gemini integration, snackbar helpers, and calculations
├── data/                  # Data layer (repositories, data sources, database models)
│   ├── datasources/       # Remote (Supabase) and local (ML Kit OCR) data sources
│   ├── models/            # Serialization-ready JSON models
│   └── repositories/      # Concrete repository implementations
├── domain/                # Business logic layer (independent of frameworks)
│   ├── entities/          # Core models/business objects
│   ├── repositories/      # Repository interfaces (contracts)
│   └── usecases/          # Granular use case triggers
└── presentation/          # UI Layer (widgets, screens, controllers/notifiers)
    ├── common/            # Shared widgets (buttons, fields, drawer) & providers
    └── features/          # Screen modules (auth, tournament, match, leaderboard, news)
```

---

## 🔄 How the App Works (Core User Flows)

### 1. Authentication & Profiling
*   Users sign up/in using email and password via [LoginScreen](file:///c:/FlutterProjects/tournament_app/lib/presentation/features/auth/login/login_screen.dart) and [RegisterScreen](file:///c:/FlutterProjects/tournament_app/lib/presentation/features/auth/register/register_screen.dart).
*   A custom [MainShell](file:///c:/FlutterProjects/tournament_app/lib/presentation/features/shell/main_shell.dart) holds the bottom navigation bar for the principal screens: HomeScreen, TournamentList, Dashboard, and Profile.
*   The [HomeDrawer](file:///c:/FlutterProjects/tournament_app/lib/presentation/common/widgets/home_drawer.dart) fetches profile data and dynamically computes stats (e.g., active tournaments count, completed matches count).

### 2. Tournament Creation Flow
Tournament organizers configure settings in a step-by-step wizard in [CreateTournamentScreen](file:///c:/FlutterProjects/tournament_app/lib/presentation/features/tournament/create/create_tournament_screen.dart):
1.  **Basic Info**: Name the tournament, specify organizer tag, select the game (currently hardcoded to BGMI), and choose the total match count (3 to 8).
2.  **Point System**: Modify the distribution points for ranks 1 through 8. Kill points default to 1 point per finish.
3.  **Schedule**: Assign dates and start times for each match.
4.  **Team List Upload**: Pick up to 2 screenshots of the team registrations or slot tables. The app runs OCR via [GeminiService](file:///c:/FlutterProjects/tournament_app/lib/core/utils/gemini_service_v2.dart) to extract slot numbers and team names. The organizer verifies this before launching.
5.  **Confirm & Launch**: Saves the tournament, creates empty match rows, and populates the teams in the database.

### 3. Match Processing Flow
Within [TournamentDetailScreen](file:///c:/FlutterProjects/tournament_app/lib/presentation/features/tournament/detail/tournament_detail_screen.dart), users click on individual matches to complete two mandatory stages:
*   **Step 1: Upload Lobby Screenshots**
    *   Organizers upload up to 3 screenshots of the in-game pre-match lobby.
    *   ML Kit and Gemini parse these images to extract which player names are in which slot box.
    *   The organizer reviews and saves the data in [VerifyScreen](file:///c:/FlutterProjects/tournament_app/lib/presentation/features/match/verify/verify_screen.dart), transitioning the match status from `pending` to `lobby_uploaded`.
*   **Step 2: Upload Result Screenshots**
    *   After the match, organizers upload 6 to 8 end-game placement screens showing final team ranks and player kill numbers.
    *   The app performs OCR/Gemini extraction to collect final placement, player names, and finishes.
    *   **Fuzzy Player Matching**: Using [MatchResolutionService](file:///c:/FlutterProjects/tournament_app/lib/core/utils/match_resolution_service.dart), the app compares names on the results screen against the lobby database (from Step 1) using a fuzzy similarity index. Players are mapped to their team slots automatically.
    *   Once validated and saved, the match changes status to `completed`. A Supabase RPC stores the final scores, updates the standings, and records player kills.

### 4. Leaderboard standing & Standings Export
*   Standings can be viewed instantly on the [LeaderboardScreen](file:///c:/FlutterProjects/tournament_app/lib/presentation/features/leaderboard/screens/leaderboard_screen.dart), showing:
    *   **Point Table**: Position, Team, Slot, and per-match point breakdown.
    *   **Top 5 MVP**: Displays the top 5 players with the highest cumulative kill counts.
*   Standings can be exported as clean graphical posters using the [LeaderboardExportCard](file:///c:/FlutterProjects/tournament_app/lib/presentation/features/leaderboard/widgets/leaderboard_export_card.dart) preview screen.

---

## 🛠️ What is Already Implemented

### Core Features & UI
*   **Authentication Flow**: Email/password authentication is fully integrated with Supabase Auth.
*   **Tournament Creation Wizard**: Completed 5-step tournament initialization layout with state persistence.
*   **Match Control**: Dynamic adding/deleting of matches (minimum 3, maximum 8 rules).
*   **Match Steps Flow**: Sequential lock rule enforcement (`pending` ➔ `lobby_uploaded` ➔ `completed`).
*   **Verification UI**: [VerifyScreen](file:///c:/FlutterProjects/tournament_app/lib/presentation/features/match/verify/verify_screen.dart) allows editing player names and finishes, and highlights low-confidence OCR results.
*   **Standings & Leaderboard**: Standings table with real-time listeners and a separate MVP rankings feed.
*   **Esports News Feed**: Fetches live esports news from the GNews API with a local static fallback in case the API limit is hit or the API key is missing.

### Infrastructure & Services
*   **On-device OCR**: [MlKitOcrService](file:///c:/FlutterProjects/tournament_app/lib/data/datasources/local/mlkit_ocr_service.dart) uses ML Kit's on-device text recognizer (completely free and offline).
*   **Gemini Service**: Re-implemented in [GeminiService](file:///c:/FlutterProjects/tournament_app/lib/core/utils/gemini_service_v2.dart) with an optimized, cost-effective pipeline:
    1.  First runs **local ML Kit OCR** to extract raw text.
    2.  If the extracted text meets the length requirements, it forwards the *text-only transcript* to Gemini (conserving image tokens and operating on higher text quota limits).
    3.  If OCR text is short/missing, it falls back to sending the raw image bytes to **Gemini Vision** using a multi-model backup (tries `gemini-2.0-flash-lite` first, and falls back to `gemini-2.0-flash` on failure).
*   **Fuzzy Search Engine**: Uses the `string_similarity` library to map players from final match results to lobby registrations, handling typos and special clan tag variations.
*   **Remote Queries**: [SupabaseDataSource](file:///c:/FlutterProjects/tournament_app/lib/data/datasources/remote/supabase_datasource.dart) handles CRUD operations, RPC invocation, and leaderboard streaming.

---

## ⏳ What is Still Pending / Future Scope

1.  **Account Deletion (TODO)**
    *   *Current State*: The "Delete Account" button in [HomeDrawer](file:///c:/FlutterProjects/tournament_app/lib/presentation/common/widgets/home_drawer.dart) triggers a dialog, but displays a placeholder snackbar instructing the user to contact support.
    *   *Required*: Implement a database cascade trigger and a Supabase Auth delete user endpoint or remote RPC function.

2.  **Social Login & Phone Sign-in**
    *   *Current State*: Interface definitions for `signInWithGoogle()`, `signInWithApple()`, and `signInWithFacebook()` exist in [SupabaseDataSource](file:///c:/FlutterProjects/tournament_app/lib/data/datasources/remote/supabase_datasource.dart), but OAuth credentials and configuration are not set up on the Supabase/Play Store project. `signInWithPhone()` is hardcoded to return a "not implemented yet" error.
    *   *Required*: Set up OTP SMS gateway providers for phone authentication and redirect deep-links for OAuth logins.

3.  **PUBG Mobile & Free Fire Support**
    *   *Current State*: Selecting PUBG Mobile or Free Fire in the creation step is currently locked ("Coming soon"). Only BGMI is supported.
    *   *Required*: Design parser prompts and templates for PUBG Mobile and Free Fire result pages/lobbies.

4.  **Flexible Point Systems**
    *   *Current State*: Ranks 9 and below are hardcoded to return 0 points (only kill points) in [MatchResolutionService](file:///c:/FlutterProjects/tournament_app/lib/core/utils/match_resolution_service.dart#L32-L56). Custom inputs are only requested for positions 1–8.
    *   *Required*: Dynamically generate rank point input slots based on game type (e.g., up to 16 places for PUBG/BGMI official systems, or up to 12 for Free Fire).

5.  **SQL Database Script Documentation**
    *   *Current State*: [supabase_schema.sql](file:///c:/FlutterProjects/tournament_app/supabase_schema.sql) at the project root is empty. The database operates on tables and functions manually configured in the remote console.
    *   *Required*: Populate [supabase_schema.sql](file:///c:/FlutterProjects/tournament_app/supabase_schema.sql) with the full Postgres schema, RLS policies, trigger functions, and RPCs (`calculate_and_insert_match_result`, `get_match_breakdown`) so developers can clone and stand up the database instantly.
