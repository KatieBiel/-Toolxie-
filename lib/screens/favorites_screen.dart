// lib/screens/favorites_screen.dart
// ============================================================================
// 💖 FAVORITES SCREEN (2025 Stable SQLite Synced Version)
// ----------------------------------------------------------------------------
// Displays user's favorite tools grouped into Daily / Weekly / Monthly sets.
// - Persistent data via SQLite (AppDatabase)
// - Global ValueNotifier sync across app
// - Fully theme-driven (AppPalette colors only)
// - Responsive layout for small & large screens
// - Reorderable grid with smooth transitions
// - Background: favorites.webp + palette.tabbartransparent overlay
// ============================================================================

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toolxie/common/appbar.dart';
import 'package:toolxie/common/tools.dart';
import 'package:toolxie/common/theme.dart';
import 'package:toolxie/screens/home_tools.dart';
import 'package:toolxie/data/database.dart';

// ============================================================================
// 🌟 FAVORITES SCREEN ROOT
// ============================================================================
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key, this.embedded = false});
  final bool embedded;

  /// Global favorite groups (daily / weekly / monthly)
  static final ValueNotifier<Map<String, List<String>>> favorites =
      ValueNotifier({"daily": [], "weekly": [], "monthly": []});

  // ---------------------------------------------------------------------------
  // 🔄 INIT / TOGGLE LOGIC
  // ---------------------------------------------------------------------------
  static Future<void> init() async {
    try {
      final db = AppDatabase.instance;
      final allFavs = await db.getAllFavorites();

      final grouped = {
        "daily": <String>[],
        "weekly": <String>[],
        "monthly": <String>[],
      };

      for (final entry in allFavs.entries) {
        final toolId = entry.key;
        final favGroup = entry.value.isNotEmpty ? entry.value : "daily";
        if (grouped.containsKey(favGroup)) {
          grouped[favGroup]!.add(toolId);
        } else {
          grouped["daily"]!.add(toolId);
        }
      }

      favorites.value = grouped;
    } catch (e) {
      debugPrint("FavoritesScreen.init error: $e");
    }
  }

  static Future<void> toggle(ToolDef tool) async {
    try {
      final db = AppDatabase.instance;
      final current = Map<String, List<String>>.from(favorites.value);
      String? currentGroup;

      for (final entry in current.entries) {
        if (entry.value.contains(tool.id)) {
          currentGroup = entry.key;
          break;
        }
      }

      if (currentGroup != null) {
        // Remove from favorites
        current[currentGroup]!.remove(tool.id);
        await db.setFavoriteGroup(tool.id, '');
      } else {
        // Add to group or default to "daily"
        final favGroup = tool.favoriteGroup.name;
        current.putIfAbsent(favGroup, () => []);
        current[favGroup]!.add(tool.id);
        await db.setFavoriteGroup(tool.id, favGroup);
      }

      favorites.value = Map<String, List<String>>.from(current);
    } catch (e) {
      debugPrint("FavoritesScreen.toggle error: $e");
    }
  }

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

// ============================================================================
// 💡 STATEFUL LOGIC + RESPONSIVE LAYOUT
// ============================================================================
class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int _gridCount = 3;

  @override
  void initState() {
    super.initState();
    FavoritesScreen.init();
  }

  int _calculateGridCount(double width) {
    if (width >= 1100) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.8, 1.4);
    final adaptiveGridCount = _calculateGridCount(width);
    final contentScale = _gridCount == 3 ? 1.0 : 1.25;

    // ------------------------------------------------------------------------
    // 🧩 BODY BUILDER — z tłem favorites.webp i overlayem
    // ------------------------------------------------------------------------
    final body = Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/favorites.webp', fit: BoxFit.cover),

        Container(color: palette.tabbartransparent.withValues(alpha: 0.4)),

        ValueListenableBuilder<Map<String, List<String>>>(
          valueListenable: FavoritesScreen.favorites,
          builder: (context, favs, _) {
            final isEmpty = favs.values.every((list) => list.isEmpty);

            if (isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.heartCircleMinus,
                        size: 48 * scale,
                        color: palette.card.withAlpha(90),
                      ),
                      SizedBox(height: 35 * scale),
                      Text(
                        tr('favorites.empty'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle(
                          palette.textTertiary.withAlpha(140),
                        ).copyWith(fontSize: 18 * scale),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ----------------------------------------------------------------
            // 🧱 SECTION BUILDER (daily / weekly / monthly)
            // ----------------------------------------------------------------
            Widget buildSection(String key, String titleKey, List<String> ids) {
              final tools = ids
                  .map(
                    (id) => allTools.firstWhere(
                      (t) => t.id == id,
                      orElse: () => ToolDef(
                        id: 'unknown',
                        titleKey: 'home.unknown_tool',
                        icon: FontAwesomeIcons.question,
                        route: '',
                        category: ToolCategory.organization,
                        favoriteGroup: FavoriteGroup.none,
                      ),
                    ),
                  )
                  .toList();

              if (tools.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: AppTextStyles.subtitle(
                      palette.card,
                    ).copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.3),
                    child: DividerWithText(
                      text: tr(titleKey),
                      textColor: palette.card,
                      lineColor: palette.card,
                    ),
                  ),
                  SizedBox(height: 12 * scale),

                  // 🧩 REORDERABLE GRID
                  ReorderableGridView.count(
                    crossAxisCount: _gridCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.0,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    dragWidgetBuilder: (index, child) => Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      child: child,
                    ),
                    onReorder: (oldIndex, newIndex) async {
                      final list = List<String>.from(ids);
                      final moved = list.removeAt(oldIndex);
                      if (newIndex > oldIndex) newIndex -= 1;
                      list.insert(newIndex, moved);

                      final updated = Map<String, List<String>>.from(
                        FavoritesScreen.favorites.value,
                      );
                      updated[key] = list;
                      FavoritesScreen.favorites.value = updated;

                      final db = AppDatabase.instance;
                      for (final id in list) {
                        await db.setFavoriteGroup(id, key);
                      }
                    },
                    children: [
                      for (final t in tools)
                        Container(
                          key: ValueKey('fav_${t.id}'),
                          alignment: Alignment.center,
                          child: ToolCard(
                            tool: t,
                            onTap: () => Navigator.pushNamed(context, t.route),
                            palette: palette,
                            scale: contentScale,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 28 * scale),
                ],
              );
            }

            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 12 * scale,
              ),
              children: [
                buildSection(
                  "daily",
                  "favorites.divider_daily",
                  favs["daily"] ?? [],
                ),
                buildSection(
                  "weekly",
                  "favorites.divider_weekly",
                  favs["weekly"] ?? [],
                ),
                buildSection(
                  "monthly",
                  "favorites.divider_monthly",
                  favs["monthly"] ?? [],
                ),
              ],
            );
          },
        ),
      ],
    );

    // ------------------------------------------------------------------------
    // 🏠 EMBEDDED MODE (no Scaffold)
    // ------------------------------------------------------------------------
    if (widget.embedded) return body;

    // ------------------------------------------------------------------------
    // 🧭 MAIN SCAFFOLD (AppBar + Floating Button)
    // ------------------------------------------------------------------------

    return Scaffold(
      appBar: const GlobalAppBar(
        titleKey: 'navbar.favorites',
        toolId: 'favorites',
      ),
      body: body,
      floatingActionButton: Builder(
        builder: (context) {
          final bottomPadding =
              MediaQuery.of(context).padding.bottom +
              120; // ✅ dynamicznie nad navbar

          return Padding(
            padding: EdgeInsets.only(bottom: bottomPadding, right: 8),
            child: FloatingActionButton(
              backgroundColor: palette.card,
              foregroundColor: palette.text.withAlpha(210),
              tooltip: tr('favorites.toggle_view'),
              elevation: 6,
              child: Icon(
                _gridCount == adaptiveGridCount
                    ? FontAwesomeIcons.tableCellsLarge
                    : FontAwesomeIcons.tableCells,
                size: 34 * scale,
              ),
              onPressed: () {
                setState(() => _gridCount = _gridCount == 3 ? 2 : 3);
              },
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ============================================================================
// 🩵 DIVIDER WITH TEXT LABEL
// ============================================================================
class DividerWithText extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color lineColor;

  const DividerWithText({
    super.key,
    required this.text,
    required this.textColor,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.of(context).size.width / 390).clamp(0.8, 1.4);

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8 * scale),
          child: Text(text, style: AppTextStyles.small(textColor)),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }
}

// ============================================================================
// 💖 Favorites Manage Dialog (przeniesienie z SettingsScreen)
// ============================================================================
Future<void> showManageFavoritesDialog(
  BuildContext context,
  AppPalette palette,
  double scale,
) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30 * scale),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.heart,
            color: palette.textPrimary,
            size: 18 * scale,
          ),
          SizedBox(width: 10 * scale),
          Text(
            tr('settings.manage_favorites'),
            style: AppTextStyles.subtitle(
              palette.textPrimary,
            ).copyWith(fontWeight: FontWeight.bold, fontSize: 16 * scale),
          ),
        ],
      ),
      content: SizedBox(
        width: 320 * scale,
        child: ValueListenableBuilder<Map<String, List<String>>>(
          valueListenable: FavoritesScreen.favorites,
          builder: (context, favs, _) {
            final allFavs = [
              ...favs["daily"] ?? const [],
              ...favs["weekly"] ?? const [],
              ...favs["monthly"] ?? const [],
            ];

            if (allFavs.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(8 * scale),
                child: Text(
                  tr('settings.no_items'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(
                    palette.textPrimary,
                  ).copyWith(fontSize: 14 * scale),
                ),
              );
            }

            String selectedTool = allFavs.first;
            String selectedGroup = "daily";

            return StatefulBuilder(
              builder: (ctx, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔻 TOOL SELECT
                  DropdownButtonFormField<String>(
                    initialValue: selectedTool,
                    dropdownColor: palette.card,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: palette.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20 * scale),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16 * scale,
                        vertical: 10 * scale,
                      ),
                    ),
                    items: allFavs.map<DropdownMenuItem<String>>((id) {
                      final titleKey = 'tools.$id.title';
                      final translated = tr(titleKey);
                      final label = (translated == titleKey)
                          ? id.replaceAll('_', ' ')
                          : translated;
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(
                          label,
                          style: AppTextStyles.body(
                            palette.textPrimary,
                          ).copyWith(fontSize: 14 * scale),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => selectedTool = v ?? allFavs.first),
                  ),
                  SizedBox(height: 16 * scale),

                  // 🔻 GROUP SELECT
                  DropdownButtonFormField<String>(
                    initialValue: selectedGroup,
                    dropdownColor: palette.card,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: palette.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20 * scale),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16 * scale,
                        vertical: 10 * scale,
                      ),
                    ),
                    items: ["daily", "weekly", "monthly"]
                        .map<DropdownMenuItem<String>>((g) {
                          return DropdownMenuItem<String>(
                            value: g,
                            child: Text(
                              tr('favorites.divider_$g'),
                              style: AppTextStyles.body(
                                palette.textPrimary,
                              ).copyWith(fontSize: 14 * scale),
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedGroup = v ?? "daily"),
                  ),
                  SizedBox(height: 24 * scale),

                  // 🔘 ACTION BUTTON
                  ElevatedButton.icon(
                    icon: Icon(
                      FontAwesomeIcons.arrowsLeftRight,
                      size: 14 * scale,
                    ),
                    label: Text(
                      tr('settings.change_group'),
                      style: AppTextStyles.button(
                        palette.textTertiary,
                      ).copyWith(fontSize: 15 * scale),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.buttonTertiary,
                      foregroundColor: palette.textTertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30 * scale),
                      ),
                      elevation: 3,
                      minimumSize: Size(200 * scale, 50 * scale),
                    ),
                    onPressed: () async {
                      final favsNew = Map<String, List<String>>.from(favs);
                      for (final g in ["daily", "weekly", "monthly"]) {
                        final list = List<String>.from(favsNew[g] ?? []);
                        list.remove(selectedTool);
                        favsNew[g] = list;
                        await AppDatabase.instance.setToolOrder(g, list);
                      }

                      final updated = List<String>.from(
                        favsNew[selectedGroup] ?? [],
                      )..add(selectedTool);
                      favsNew[selectedGroup] = updated;
                      FavoritesScreen.favorites.value = favsNew;

                      await AppDatabase.instance.setToolOrder(
                        selectedGroup,
                        updated,
                      );
                      await AppDatabase.instance.setFavoriteGroup(
                        selectedTool,
                        selectedGroup,
                      );

                      if (!ctx.mounted) return; // ✅ zabezpieczenie

                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            "${tr('favorites.moved_to')} ${tr('favorites.divider_$selectedGroup')}",
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
