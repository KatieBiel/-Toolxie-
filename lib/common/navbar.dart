// lib/common/navbar.dart
// ============================================================================
// 🧭 NAV BAR – floating glass design (2025 Refactor)
// ----------------------------------------------------------------------------
// - Fully themed via AppPalette + AppTextStyles
// - Responsive (scales on small and large screens)
// - iOS-like glass blur with shadow
// - All texts localized (navbar.* keys)
// - Uses FontAwesome icons exclusively
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toolxie/common/theme.dart';
import 'package:toolxie/screens/account_screen.dart';
import 'package:toolxie/screens/favorites_screen.dart';
import 'package:toolxie/screens/home_screen.dart';
import 'package:toolxie/screens/settings_screen.dart';

/// ============================================================================
/// 🌐 NavBar Widget
/// Central bottom navigation bar with glass effect and adaptive scaling.
/// ============================================================================
class NavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavBar({super.key, required this.currentIndex, required this.onTap});

  static const double _baseIconSize = 22;
  static const double _activeIconSize = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    final mq = MediaQuery.of(context);
    final double scale = (mq.size.width < 360)
        ? 0.9
        : (mq.size.width > 800)
        ? 1.2
        : 1.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 12 * scale),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28 * scale),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: palette.navBar.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28 * scale),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow.withValues(alpha: 0.25),
                    blurRadius: 12 * scale,
                    offset: Offset(0, 4 * scale),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: onTap,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,

                // 🎨 Color & typography
                selectedItemColor: palette.navBarText,
                unselectedItemColor: palette.navBarText.withValues(alpha: 0.6),
                selectedFontSize: 12 * scale,
                unselectedFontSize: 12 * scale,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
                selectedIconTheme: IconThemeData(
                  size: _activeIconSize * scale,
                  color: palette.navBarText,
                ),
                unselectedIconTheme: IconThemeData(
                  size: _baseIconSize * scale,
                  color: palette.navBarText.withValues(alpha: 0.6),
                ),
                showSelectedLabels: true,
                showUnselectedLabels: true,

                // 🧩 Icons & labels (localized)
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(FontAwesomeIcons.house),
                    label: tr('navbar.home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(FontAwesomeIcons.circleUser),
                    label: tr('navbar.account'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(FontAwesomeIcons.heart),
                    activeIcon: const Icon(FontAwesomeIcons.solidHeart),
                    label: tr('navbar.favorites'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(FontAwesomeIcons.gear),
                    label: tr('navbar.settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 🏠 MainScaffold – wraps all main pages with NavBar and adaptive background.
/// ============================================================================
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  final GlobalKey<AccountScreenState> _accountKey =
      GlobalKey<AccountScreenState>();

  List<Widget> _pages(BuildContext context) => [
    const HomeScreen(),
    AccountScreen(
      key: _accountKey, // ✅ tu przekazujemy klucz
    ),
    FavoritesScreen(key: ValueKey('favorites_${context.locale.languageCode}')),
    const SettingsScreen(),
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);

    if (index == 1 && _accountKey.currentState != null) {
      _accountKey.currentState!.refreshAllStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages(context)),
      bottomNavigationBar: NavBar(currentIndex: _currentIndex, onTap: _onTap),
    );
  }
}
