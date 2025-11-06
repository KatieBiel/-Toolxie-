// lib/main.dart
// ============================================================================
// 🚀 MAIN ENTRY POINT — Toolxie 2025 (SQLite local + Firebase premium sync)
// ----------------------------------------------------------------------------
// - Creates local user in SQLite with UID + recoveryCode
// - Initializes Firebase ONLY if user has premium or VIP code
// - Loads EasyLocalization + Riverpod + Theme
// - Sets global SystemUIOverlayStyle (status + nav bar colors)
// - Initializes local notifications (Android + iOS)
// - Pre-initializes key tool databases (Planner, Todos, Budget, Notes)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// 🌩️ Firebase & Data
import 'package:firebase_core/firebase_core.dart';
import 'package:toolxie/data/auth_service.dart';
import 'package:toolxie/data/firebase_options.dart';
import 'package:toolxie/data/database.dart';
import 'package:toolxie/data/providers.dart';

// 🌿 App Core
import 'package:toolxie/common/theme.dart';
import 'package:toolxie/common/router.dart';
import 'package:toolxie/common/tools.dart';
import 'package:toolxie/screens/favorites_screen.dart';
import 'package:toolxie/common/notifications_service.dart';

// 🧩 Tool Databases (to ensure tables exist before sync)
import 'package:toolxie/tools/organization/todos/todos_database.dart';
import 'package:toolxie/tools/organization/planner/planner_database.dart';
import 'package:toolxie/tools/organization/budget/budget_database.dart';
import 'package:toolxie/tools/organization/notes/notes_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  debugPrint('🚀 [Main] Toolxie starting...');

  try {
    // 🧠 Initialize SQLite (local data always available)
    debugPrint('💾 [Main] Initializing local database...');
    final db = AppDatabase.instance;
    await db.ensureLocalUser();
    debugPrint('✅ [Main] Local user ensured.');

    // 🔥 Update daily streak (days in a row)
    debugPrint('📆 [Main] Updating daily streak...');
    await db.updateDailyStreak();
    debugPrint('✅ [Main] Daily streak updated.');

    // 🧱 Pre-initialize key tool databases to avoid "no such table" errors
    debugPrint('🧱 [Main] Ensuring core tool tables exist...');
    await TodosDatabase.instance.database;
    await PlannerDatabase.instance.database;
    await BudgetDatabase.instance.database;
    await NotesDatabase.instance.database;
    debugPrint('✅ [Main] Core tool tables ready.');

    // 🧹 Cleanup invalid favorites
    final validToolIds = allTools.map((t) => t.id).toList();
    await db.cleanupOrphanedFavorites(validToolIds);
    await FavoritesScreen.init();
    debugPrint('✅ [Main] Favorites initialized and cleaned up.');

    // 🔔 Initialize local notifications (Android + iOS)
    debugPrint('🔔 [Main] Initializing NotificationService...');
    await NotificationService.init();
    debugPrint('✅ [Main] NotificationService initialized.');

    // 💎 Initialize Firebase only for premium or VIP users
    debugPrint('🔥 [Main] Checking Firebase condition (premium/VIP)...');
    await _initPremiumFirebase();
    debugPrint('✅ [Main] Firebase initialized (if needed).');

    // 🏁 Run app
    debugPrint('🏁 [Main] Running ToolxieApp...');
    runApp(
      ProviderScope(
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('pl'), Locale('nl')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: const ToolxieApp(),
        ),
      ),
    );

    debugPrint('🎯 [Main] Toolxie fully started.');
  } catch (e, stack) {
    debugPrint('❌ [Main] Startup error: $e');
    debugPrint('🧩 [Main] Stack trace:\n$stack');
  }
}

// ============================================================================
// 🔐 INIT FIREBASE ONLY FOR PREMIUM USERS
// ============================================================================
Future<void> _initPremiumFirebase() async {
  try {
    final db = AppDatabase.instance;
    final status = await db.getSubscriptionStatus();
    final hasPremium = status['subscriptionActive'] || status['vipActive'];

    if (!hasPremium) {
      debugPrint('💡 Free user — Firebase not needed yet');
      return;
    }

    await ensureFirebaseInitialized();

    // 🔐 Full Firebase + Tool sync for premium users
    debugPrint('👑 Premium/VIP detected → starting full sync...');
    await AuthService.activateFirebaseAfterVip();
    debugPrint('✅ Full Firebase + Tool sync completed.');
  } catch (e) {
    debugPrint('❌ Firebase init error: $e');
  }
}

// ============================================================================
// 🧩 GLOBAL HELPER — Safe Firebase initialization
// ============================================================================
Future<void> ensureFirebaseInitialized() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      debugPrint('💡 Firebase already initialized — skipping');
      return;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase init error: $e');
  }
}

// ============================================================================
// 🌿 ROOT APPLICATION
// ============================================================================
class ToolxieApp extends ConsumerStatefulWidget {
  const ToolxieApp({super.key});

  @override
  ConsumerState<ToolxieApp> createState() => _ToolxieAppState();
}

class _ToolxieAppState extends ConsumerState<ToolxieApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializePremiumState();
    });
  }

  Future<void> _initializePremiumState() async {
    try {
      await updateSubscriptionState(ref);
      debugPrint('💎 Premium state initialized at launch');
    } catch (e) {
      debugPrint('⚠️ Premium state init failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);

    final themeData = switch (themeMode) {
      AppThemeMode.light => AppTheme.light,
      AppThemeMode.medium => AppTheme.medium,
      AppThemeMode.dark => AppTheme.dark,
    };

    final globalTheme = themeData.copyWith(
      textTheme: GoogleFonts.quicksandTextTheme(themeData.textTheme),
      primaryTextTheme: GoogleFonts.quicksandTextTheme(
        themeData.primaryTextTheme,
      ),
    );

    return MaterialApp(
      title: 'Toolxie',
      debugShowCheckedModeBanner: false,
      theme: globalTheme,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
    );
  }
}
