// lib/tools/tools.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toolxie/common/router.dart';
import 'package:toolxie/common/theme.dart';
import 'package:toolxie/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================================
/// 1️⃣ ENUMS – Tool categories & favorite grouping
/// ============================================================================
enum ToolCategory { organization, growth, life }

enum FavoriteGroup { daily, weekly, monthly, none }

/// ============================================================================
/// 2️⃣ EXTENSIONS – Category color & typography helpers
/// ============================================================================
extension ToolCategoryX on ToolCategory {
  /// 🎨 Base accent color per category
  Color baseColor(AppPalette palette) {
    return switch (this) {
      ToolCategory.organization => palette.orgColor,
      ToolCategory.growth => palette.growthColor,
      ToolCategory.life => palette.lifeColor,
    };
  }

  /// 🌈 Pastel background color for tool cards
  Color bgColor(AppPalette palette) {
    return switch (this) {
      ToolCategory.organization => palette.toolCardBgOrg,
      ToolCategory.growth => palette.toolCardBgGrowth,
      ToolCategory.life => palette.toolCardBgLife,
    };
  }

  /// ⚪ Circle color inside the card
  Color circleColor(AppPalette palette) => palette.toolCardCircle;

  /// 🎯 Icon color (strong category accent)
  Color iconColor(AppPalette palette) => baseColor(palette);

  /// 🧾 Text color for tool titles
  Color textColor(AppPalette palette) => palette.toolCardText;

  /// 🧩 Returns the full set of colors used by the card
  (Color bg, Color circle, Color icon, Color text) colorsForCard(AppPalette p) {
    return (bgColor(p), circleColor(p), iconColor(p), textColor(p));
  }

  /// 🏷️ Category header style used in Home and Favorites screens
  TextStyle categoryTitleTextStyle(BuildContext context, AppPalette palette) {
    final tt = Theme.of(context).textTheme;
    return (tt.labelLarge ?? const TextStyle(fontSize: 14)).copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: baseColor(palette),
    );
  }
}

/// ============================================================================
/// 3️⃣ TOOL MODEL – defines metadata for each module
/// ============================================================================
class ToolDef {
  final String id; // Internal ID (e.g. "todos")
  final String titleKey; // Localization key
  final IconData icon; // FontAwesome icon
  final String route; // Route name from AppRouter
  final ToolCategory category; // Organization / Growth / Life
  final bool isComingSoon; // Hides unfinished tools
  final FavoriteGroup favoriteGroup; // Optional daily/weekly/monthly grouping
  final bool isPremium; // For potential premium tools (future-ready)

  const ToolDef({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.route,
    required this.category,
    this.isComingSoon = false,
    required this.favoriteGroup,
    this.isPremium = false,
  });

  /// 🎨 Returns card colors based on the active theme
  (Color bg, Color circle, Color icon, Color text) cardColors(AppPalette p) {
    if (isComingSoon) {
      return (
        AppColors.grey,
        AppColors.white,
        AppColors.dark,
        AppColors.dark.withValues(alpha: 0.6),
      );
    }
    return category.colorsForCard(p);
  }
}

// ============================================================================
// 4️⃣ ALL TOOLS – global registry of every Toolxie module (with Premium flags)
// ============================================================================

final allTools = <ToolDef>[
  // --------------------------------------------------------------------------
  // 🗂️ ORGANIZATION
  // --------------------------------------------------------------------------
  ToolDef(
    id: 'todos',
    titleKey: 'tools.todos',
    icon: FontAwesomeIcons.squareCheck,
    route: AppRouter.todos,
    category: ToolCategory.organization,
    favoriteGroup: FavoriteGroup.daily,
    isPremium: false, // ✅ FREE
  ),
  ToolDef(
    id: 'notes',
    titleKey: 'tools.notes',
    icon: FontAwesomeIcons.clipboard,
    route: AppRouter.notes,
    category: ToolCategory.organization,
    favoriteGroup: FavoriteGroup.daily,
    isPremium: false, // ✅ FREE
  ),
  ToolDef(
    id: 'planner',
    titleKey: 'tools.planner',
    icon: FontAwesomeIcons.calendar,
    route: AppRouter.planner,
    category: ToolCategory.organization,
    favoriteGroup: FavoriteGroup.daily,
    isPremium: true, // 👑 PREMIUM
  ),
  ToolDef(
    id: 'menu',
    titleKey: 'tools.menu',
    icon: FontAwesomeIcons.utensils,
    route: AppRouter.menu,
    category: ToolCategory.organization,
    favoriteGroup: FavoriteGroup.weekly,
    isPremium: true, // 👑 PREMIUM
  ),
  ToolDef(
    id: 'house',
    titleKey: 'tools.house',
    icon: FontAwesomeIcons.houseChimney,
    route: AppRouter.house,
    category: ToolCategory.organization,
    favoriteGroup: FavoriteGroup.weekly,
    isPremium: true, // 👑 PREMIUM
  ),
  ToolDef(
    id: 'budget',
    titleKey: 'tools.budget',
    icon: FontAwesomeIcons.creditCard,
    route: AppRouter.budget,
    category: ToolCategory.organization,
    favoriteGroup: FavoriteGroup.weekly,
    isPremium: true, // 👑 PREMIUM
  ),

  // --------------------------------------------------------------------------
  // 🌱 GROWTH
  // --------------------------------------------------------------------------
  ToolDef(
    id: 'goals',
    titleKey: 'tools.goals',
    icon: FontAwesomeIcons.bullseye,
    route: AppRouter.goals,
    category: ToolCategory.growth,
    favoriteGroup: FavoriteGroup.monthly,
    isPremium: false, // ✅ FREE
  ),
  ToolDef(
    id: 'habits',
    titleKey: 'tools.habits',
    icon: FontAwesomeIcons.circleCheck,
    route: AppRouter.habits,
    category: ToolCategory.growth,
    favoriteGroup: FavoriteGroup.daily,
    isPremium: false, // ✅ FREE
  ),
  ToolDef(
    id: 'routines',
    titleKey: 'tools.routines',
    icon: FontAwesomeIcons.repeat,
    route: AppRouter.routines,
    category: ToolCategory.growth,
    favoriteGroup: FavoriteGroup.daily,
    isPremium: true, // 👑 PREMIUM
  ),
  ToolDef(
    id: 'codex',
    titleKey: 'tools.codex',
    icon: FontAwesomeIcons.bookOpen,
    route: AppRouter.codex,
    category: ToolCategory.growth,
    favoriteGroup: FavoriteGroup.monthly,
    isPremium: true, // 👑 PREMIUM
  ),
  ToolDef(
    id: 'inspirations',
    titleKey: 'tools.inspirations',
    icon: FontAwesomeIcons.lightbulb,
    route: AppRouter.inspirations,
    category: ToolCategory.growth,
    favoriteGroup: FavoriteGroup.weekly,
    isPremium: true, // 👑 PREMIUM
  ),
  ToolDef(
    id: 'reflections',
    titleKey: 'tools.reflections',
    icon: FontAwesomeIcons.penToSquare,
    route: AppRouter.reflections,
    category: ToolCategory.growth,
    favoriteGroup: FavoriteGroup.weekly,
    isPremium: true, // 👑 PREMIUM
  ),

  // --------------------------------------------------------------------------
  // 💖 LIFE / WELLBEING
  // --------------------------------------------------------------------------
  ToolDef(
    id: 'journal',
    titleKey: 'tools.journal',
    icon: FontAwesomeIcons.book,
    route: AppRouter.journal,
    category: ToolCategory.life,
    favoriteGroup: FavoriteGroup.daily,
    isPremium: false, // ✅ FREE
  ),
  ToolDef(
    id: 'affirmations',
    titleKey: 'tools.affirmations',
    icon: FontAwesomeIcons.comment,
    route: AppRouter.affirmations,
    category: ToolCategory.life,
    favoriteGroup: FavoriteGroup.daily,
    isPremium: false, // ✅ FREE
  ),
  ToolDef(
    id: 'relations',
    titleKey: 'tools.relations',
    icon: FontAwesomeIcons.heart,
    route: AppRouter.relations,
    category: ToolCategory.life,
    favoriteGroup: FavoriteGroup.monthly,
    isPremium: true, // 👑 PREMIUM
  ),
  ToolDef(
    id: 'achievements',
    titleKey: 'tools.achievements',
    icon: FontAwesomeIcons.trophy,
    route: AppRouter.achievements,
    category: ToolCategory.life,
    favoriteGroup: FavoriteGroup.weekly,
    isPremium: true, // 👑 PREMIUM
  ),
  ToolDef(
    id: 'vitality',
    titleKey: 'tools.vitality',
    icon: FontAwesomeIcons.bolt,
    route: AppRouter.vitality,
    category: ToolCategory.life,
    favoriteGroup: FavoriteGroup.monthly,
    isPremium: true, // 👑 PREMIUM
  ),
  ToolDef(
    id: 'care',
    titleKey: 'tools.care',
    icon: FontAwesomeIcons.spa,
    route: AppRouter.care,
    category: ToolCategory.life,
    favoriteGroup: FavoriteGroup.weekly,
    isPremium: true, // 👑 PREMIUM
  ),
];

/// ============================================================================
/// 5️⃣ SELECTORS – quick category accessors
/// ============================================================================
List<ToolDef> get toolsOrganization =>
    allTools.where((t) => t.category == ToolCategory.organization).toList();

List<ToolDef> get toolsGrowth =>
    allTools.where((t) => t.category == ToolCategory.growth).toList();

List<ToolDef> get toolsLife =>
    allTools.where((t) => t.category == ToolCategory.life).toList();

/// ============================================================================
/// 6️⃣ UTILS – helper accessors
/// ============================================================================

/// Returns a tool definition by its internal ID.
ToolDef? getToolById(String id) {
  try {
    return allTools.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
}

/// Returns all premium tools (future use).
List<ToolDef> get premiumTools => allTools.where((t) => t.isPremium).toList();

/// Returns all non-premium (free) tools.
List<ToolDef> get freeTools => allTools.where((t) => !t.isPremium).toList();

/// ============================================================================
/// 7️⃣ FILTER – premium override based on user subscription
/// ============================================================================

/// Zwraca listę narzędzi z pominięciem ograniczeń premium, jeśli subskrypcja aktywna
List<ToolDef> getVisibleTools(WidgetRef ref) {
  final hasPremium = ref.watch(subscriptionActiveProvider);
  if (hasPremium) return allTools; // 🔓 Wszystko dostępne
  return allTools; // 👑 Premium ukryte / oznaczone w UI
}

/// Zwraca pojedyncze narzędzie z uwzględnieniem subskrypcji
ToolDef? getToolVisibleById(WidgetRef ref, String id) {
  final hasPremium = ref.watch(subscriptionActiveProvider);
  final tool = getToolById(id);
  if (tool == null) return null;
  if (hasPremium) {
    return ToolDef(
      id: tool.id,
      titleKey: tool.titleKey,
      icon: tool.icon,
      route: tool.route,
      category: tool.category,
      favoriteGroup: tool.favoriteGroup,
      isComingSoon: tool.isComingSoon,
      isPremium: false, // 👑 Wyłącz premium dla aktywnego suba
    );
  }
  return tool;
}
