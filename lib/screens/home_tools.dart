// lib/screens/home_tools.dart
// ============================================================================
// 🧰 HOME TOOLS (2025 Stable Refactor)
// ----------------------------------------------------------------------------
// - Responsive grid layout for all screen sizes
// - Theme-driven colors via AppPalette & ToolDef.cardColors()
// - Scalable typography (MediaQuery-based)
// - Localized strings (PL / EN / NL)
// - State via Riverpod / SQLite (no SharedPreferences)
// ============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:toolxie/common/theme.dart';
import 'package:toolxie/common/tools.dart';
import 'package:toolxie/data/providers.dart';
import 'package:toolxie/screens/freetrial.dart';

// ============================================================================
// 🌿 HOME TOOLS ROOT
// Displays category tabs and a responsive grid of tool cards.
// ============================================================================
class HomeTools extends ConsumerStatefulWidget {
  final ToolCategory activeCategory;
  final ValueChanged<ToolCategory> onCategoryChange;
  final List<ToolDef> itemsOrg;
  final List<ToolDef> itemsGrowth;
  final List<ToolDef> itemsLife;

  const HomeTools({
    super.key,
    required this.activeCategory,
    required this.onCategoryChange,
    required this.itemsOrg,
    required this.itemsGrowth,
    required this.itemsLife,
  });

  @override
  ConsumerState<HomeTools> createState() => _HomeToolsState();
}

class _HomeToolsState extends ConsumerState<HomeTools> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.activeCategory.index);
  }

  void _onPageChanged(int index) {
    widget.onCategoryChange(ToolCategory.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    // 👑 Kluczowy fragment — obserwujemy status premium,
    // dzięki czemu HomeTools automatycznie się odświeży po zmianie
    final _ = ref.watch(subscriptionActiveProvider);

    final palette = ref.watch(currentPaletteProvider);
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.8, 1.5);

    final crossAxisCount = 3;
    final maxItems = [
      widget.itemsOrg.length,
      widget.itemsGrowth.length,
      widget.itemsLife.length,
    ].reduce(max);

    const baseCell = 124.0;
    final rows = max(1, (maxItems / crossAxisCount).ceil());
    final gridHeight = rows * (baseCell * scale) + (rows - 1) * (16 * scale);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionDivider(scale: scale, color: palette.textPrimary),
        Padding(
          padding: EdgeInsets.only(bottom: 8 * scale),
          child: Text(
            tr('home.tools_section_prefix'),
            textAlign: TextAlign.center,
            style: AppTextStyles.title(
              palette.textPrimary,
            ).copyWith(fontSize: 22 * scale, fontWeight: FontWeight.w700),
          ),
        ),

        // 🗂️ Category Tabs
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * scale),
          child: CategoryTabs(
            active: widget.activeCategory,
            onTap: (cat) {
              final page = ToolCategory.values.indexOf(cat);
              _pageController.animateToPage(
                page,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              widget.onCategoryChange(cat);
            },
            scale: scale,
          ),
        ),

        // 🧩 Tools Grid
        SizedBox(
          height: max(gridHeight, MediaQuery.of(context).size.height * 0.4),
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildGrid(widget.itemsOrg, crossAxisCount, scale, palette),
              _buildGrid(widget.itemsGrowth, crossAxisCount, scale, palette),
              _buildGrid(widget.itemsLife, crossAxisCount, scale, palette),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 🧩 Adaptive grid builder for a given category
  // --------------------------------------------------------------------------
  Widget _buildGrid(
    List<ToolDef> items,
    int crossAxisCount,
    double scale,
    AppPalette palette,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16 * scale),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16 * scale,
        mainAxisSpacing: 16 * scale,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final tool = items[i];
        return ToolCard(
          tool: tool,
          onTap: () => Navigator.pushNamed(context, tool.route),
          scale: scale,
          palette: palette,
        );
      },
    );
  }
}

// ============================================================================
// ⭐ SECTION DIVIDER (Decorative Star)
// ============================================================================
class _SectionDivider extends StatelessWidget {
  final double scale;
  final Color color;

  const _SectionDivider({required this.scale, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 12 * scale),
    child: Row(
      children: [
        Expanded(
          child: Divider(
            indent: 32 * scale,
            endIndent: 8 * scale,
            color: color.withAlpha(120),
          ),
        ),
        Icon(
          FontAwesomeIcons.star,
          size: 14 * scale,
          color: color.withAlpha(120),
        ),
        Expanded(
          child: Divider(
            indent: 8 * scale,
            endIndent: 32 * scale,
            color: color.withAlpha(120),
          ),
        ),
      ],
    ),
  );
}

// ============================================================================
// 🗂️ CATEGORY TABS (Organization / Growth / Life)
// ============================================================================
class CategoryTabs extends ConsumerWidget {
  final ToolCategory active;
  final ValueChanged<ToolCategory> onTap;
  final double scale;

  const CategoryTabs({
    super.key,
    required this.active,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    final width = MediaQuery.of(context).size.width;
    final fontSize = (width / 35).clamp(10.0, 14.0);

    Widget tab(ToolCategory cat, String key, IconData icon, Color color) {
      final activeTab = (cat == active);

      return Expanded(
        child: InkWell(
          onTap: () => onTap(cat),
          borderRadius: BorderRadius.circular(10 * scale),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10 * scale),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20 * scale, color: color),
                SizedBox(height: 6 * scale),
                Stack(
                  children: [
                    Text(
                      tr(key),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small(palette.textPrimary).copyWith(
                        fontSize: fontSize + 1,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 0.8
                          ..color = palette.textPrimary.withAlpha(180),
                      ),
                    ),
                    Text(
                      tr(key),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small(palette.textPrimary).copyWith(
                        fontSize: fontSize + 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * scale),
                Container(
                  height: 3 * scale,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: activeTab ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(2 * scale),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(
          ToolCategory.organization,
          'home.section_organization',
          FontAwesomeIcons.wrench,
          palette.orgColor,
        ),
        tab(
          ToolCategory.growth,
          'home.section_growth',
          FontAwesomeIcons.seedling,
          palette.growthColor,
        ),
        tab(
          ToolCategory.life,
          'home.section_life',
          FontAwesomeIcons.solidHeart,
          palette.lifeColor,
        ),
      ],
    );
  }
}

// ============================================================================
// 🧩 TOOL CARD – pastel tile + gold border + crown for non-premium users
// ============================================================================
class ToolCard extends ConsumerWidget {
  final ToolDef tool;
  final VoidCallback onTap;
  final AppPalette palette;
  final double scale;

  const ToolCard({
    super.key,
    required this.tool,
    required this.onTap,
    required this.palette,
    this.scale = 1.0,
  });

  static const _baseIcon = 28.0;
  static const _baseBadge = 56.0;
  static const _baseFont = 14.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium = ref.watch(subscriptionActiveProvider);
    final (bg, _, iconColor, _) = tool.cardColors(palette);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 🌈 main card
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: tool.isPremium && !hasPremium
                ? Border.all(
                    width: 2,
                    color: palette.gold.withValues(alpha: 0.9),
                  )
                : null,
            boxShadow: AppShadows.soft(palette.shadow),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () async {
                final hasPremiumNow = ref.read(subscriptionActiveProvider);

                if (tool.isPremium && !hasPremiumNow) {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const FreeTrialScreen(trialExpired: false),
                  );

                  if (result == 'trial_started') {
                    ref.read(subscriptionActiveProvider.notifier).state = true;

                    ref.invalidate(premiumStatusProvider);
                    ref.invalidate(hasPremiumAccessProvider);

                    debugPrint(
                      '💎 Trial started → premium odblokowany (ToolCard)',
                    );
                  }
                } else {
                  onTap();
                }
              },
              borderRadius: BorderRadius.circular(22),
              splashColor: iconColor.withAlpha(40),
              highlightColor: iconColor.withAlpha(20),
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: _baseBadge,
                        height: _baseBadge,
                        decoration: BoxDecoration(
                          color: palette.toolCardCircle,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black.withAlpha(30),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          tool.icon,
                          size: _baseIcon,
                          color: iconColor,
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            tr(tool.titleKey),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                            style: AppTextStyles.subtitle(palette.textTertiary)
                                .copyWith(
                                  fontSize: _baseFont,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 👑 Premium badge
        if (tool.isPremium && !hasPremium)
          Positioned(
            top: 7 * scale,
            right: 7 * scale,
            child: Container(
              padding: EdgeInsets.all(5 * scale),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.gold,
                boxShadow: AppShadows.soft(palette.shadow),
              ),
              child: Icon(
                FontAwesomeIcons.crown,
                size: 12 * scale,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
