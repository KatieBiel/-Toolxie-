// lib/common/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toolxie/data/database.dart';

// Core
import 'package:toolxie/screens/splash_screen.dart';
import 'package:toolxie/screens/welcome_screen.dart';
import 'package:toolxie/screens/name_screen.dart';
import 'package:toolxie/common/navbar.dart';

// Tools
import 'package:toolxie/tools/organization/notes/notes_screen.dart';
import 'package:toolxie/tools/organization/todos/todos_screen.dart';
import 'package:toolxie/tools/organization/planner/planner_screen.dart';
import 'package:toolxie/tools/organization/menu/menu_screen.dart';
import 'package:toolxie/tools/organization/house/house_screen.dart';
import 'package:toolxie/tools/organization/budget/budget_screen.dart';

import 'package:toolxie/tools/growth/codex/codex_screen.dart';
import 'package:toolxie/tools/growth/goals/goals_screen.dart';
import 'package:toolxie/tools/growth/habits/habits_screen.dart';
import 'package:toolxie/tools/growth/routines/routines_screen.dart';
import 'package:toolxie/tools/growth/inspirations/inspirations_screen.dart';
import 'package:toolxie/tools/growth/reflections/reflections_screen.dart';

import 'package:toolxie/tools/wellbeing/affirmations/affirmations_screen.dart';
import 'package:toolxie/tools/wellbeing/care/care_screen.dart';
import 'package:toolxie/tools/wellbeing/journal/journal_screen.dart';
import 'package:toolxie/tools/wellbeing/relations/relations_screen.dart';
import 'package:toolxie/tools/wellbeing/achievements/achievements_screen.dart';
import 'package:toolxie/tools/wellbeing/vitality/vitality_screen.dart';

/// ============================================================================
/// 🚀 ROUTER
/// ============================================================================
class AppRouter {
  // ------------------------------------------------------
  // CORE ROUTES
  // ------------------------------------------------------
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String name = '/name';
  static const String home = '/home'; // ⬅️ MainScaffold with NavBar

  // ------------------------------------------------------
  // TOOL ROUTES
  // ------------------------------------------------------
  static const String notes = '/tools/notes';
  static const String todos = '/tools/todos';
  static const String menu = '/tools/menu';
  static const String house = '/tools/house';
  static const String planner = '/tools/planner';
  static const String budget = '/tools/budget';

  static const String codex = '/tools/codex';
  static const String goals = '/tools/goals';
  static const String habits = '/tools/habits';
  static const String routines = '/tools/routines';
  static const String inspirations = '/tools/inspirations';
  static const String reflections = '/tools/reflections';

  static const String affirmations = '/tools/affirmations';
  static const String journal = '/tools/journal';
  static const String relations = '/tools/relations';
  static const String care = '/tools/care';
  static const String achievements = '/tools/achievements';
  static const String vitality = '/tools/vitality';

  // ------------------------------------------------------
  // ROUTE GENERATOR
  // ------------------------------------------------------
  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return _page(const SplashScreen(), splash);
      case welcome:
        return _page(const WelcomeScreen(), welcome);
      case name:
        return _page(const NameScreen(), name);
      case home:
        return _page(const MainScaffold(), home);

      // Tools
      case notes:
        return _page(const NotesScreen(), notes);
      case planner:
        return _page(const PlannerScreen(), planner);
      case menu:
        return _page(const MenuScreen(), menu);
      case todos:
        return _page(const TodosScreen(), todos);
      case budget:
        return _page(const BudgetScreen(), budget);
      case house:
        return _page(const HouseScreen(), house);
      case codex:
        return _page(const CodexScreen(), codex);
      case goals:
        return _page(const GoalsScreen(), goals);
      case habits:
        return _page(const HabitsScreen(), habits);
      case routines:
        return _page(const RoutinesScreen(), routines);
      case inspirations:
        return _page(const InspirationsScreen(), inspirations);
      case reflections:
        return _page(const ReflectionsScreen(), reflections);
      case affirmations:
        return _page(const AffirmationsScreen(), affirmations);
      case journal:
        return _page(const JournalScreen(), journal);
      case relations:
        return _page(const RelationsScreen(), relations);
      case vitality:
        return _page(const VitalityScreen(), vitality);
      case care:
        return _page(const CareScreen(), care);
      case achievements:
        return _page(const AchievementsScreen(), achievements);

      default:
        return _page(const SplashScreen(), splash);
    }
  }

  static MaterialPageRoute _page(Widget child, String name) =>
      MaterialPageRoute(
        settings: RouteSettings(name: name),
        builder: (_) => child,
      );

  // ------------------------------------------------------
  // 🧠 INITIAL ROUTE DECISION (using SQLite)
  // ------------------------------------------------------
  static Future<String> decideStartRoute(WidgetRef ref) async {
    final db = AppDatabase.instance;

    final seenWelcome = await db.isWelcomeSeen();
    final userName = await db.getUserName();

    debugPrint(
      '🎬 decideStartRoute → seenWelcome=$seenWelcome | userName=$userName',
    );

    if (!seenWelcome) return welcome;
    if (userName == null || userName.trim().isEmpty) return name;
    return home;
  }

  // ------------------------------------------------------
  // NAV HELPERS
  // ------------------------------------------------------
  static void goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(home, (r) => false);
  }
}
