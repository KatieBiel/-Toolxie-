// lib/screens/welcome_screen.dart
// ============================================================================
// 🌿 Welcome Screen – first-time onboarding info
// Refactor goals (2025):
// - Fully responsive (MediaQuery scaling)
// - All colors/styles from theme.dart
// - Translations from JSON only
// - Animation + clean structure
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:toolxie/common/theme.dart';
import 'package:toolxie/common/router.dart';
import 'package:toolxie/data/database.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  bool _visible = false;

  // --------------------------------------------------------------------------
  // 🎬 Init & Animation Setup
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    final curve = CurvedAnimation(parent: _ctl, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, .45),
      end: Offset.zero,
    ).animate(curve);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/icons/leaf.png'), context);
      _ctl.forward();
      setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // 🧭 Navigation
  // --------------------------------------------------------------------------
  Future<void> _goNext(BuildContext context) async {
    try {
      await AppDatabase.instance.setWelcomeSeen(true);
    } catch (e) {
      debugPrint('Error saving welcome flag: $e');
    }
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.name);
  }

  // --------------------------------------------------------------------------
  // 🌈 Helpers
  // --------------------------------------------------------------------------
  LinearGradient _gradient(AppPalette palette) => palette.backgroundGradient;

  // --------------------------------------------------------------------------
  // 🌱 Header Section (logo + title)
  // --------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, double width, AppPalette palette) {
    final textColor = palette.text;
    final scale = width / 390;
    final logoHeight = (width * 0.50).clamp(90.0, 140.0);
    final titleFont = (28.0 * scale).clamp(24.0, 34.0);
    final subtitleFont = (18.0 * scale).clamp(16.0, 20.0);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // 🌿 Animated Leaf
        Transform.translate(
          offset: const Offset(0, 85),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 700),
            opacity: _visible ? 1 : 0,
            child: SlideTransition(
              position: _slide,
              child: ScaleTransition(
                scale: _scale,
                child: Image.asset(
                  'assets/images/icons/leaf.png',
                  height: logoHeight,
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        // 🧾 Title + Subtitle
        Column(
          children: [
            const SizedBox(height: 10),
            Text(
              tr('welcome.title'),
              textAlign: TextAlign.center,
              style: AppTextStyles.title(
                textColor,
              ).copyWith(fontSize: titleFont, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                tr('welcome.subtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.body(textColor).copyWith(
                  fontSize: subtitleFont,
                  height: 1.45,
                  color: textColor.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // ✅ Benefit point with checkmark
  // --------------------------------------------------------------------------
  Widget _buildPoint(String text, Color fg, double font) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: fg.withValues(alpha: .15),
            child: Icon(Icons.check_rounded, size: 18, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body(
                fg,
              ).copyWith(fontSize: font, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 🪴 Benefits Card
  // --------------------------------------------------------------------------
  Widget _buildBenefits(AppPalette palette, double width) {
    final scale = width / 390;
    final font = (15 * scale).clamp(14.0, 17.0);
    final titleSize = (20 * scale).clamp(18.0, 22.0);

    return Transform.translate(
      offset: const Offset(0, 60),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.green, palette.turquoise],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Card(
          color: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  tr('welcome.benefits_title'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle(
                    Colors.white,
                  ).copyWith(fontSize: titleSize, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _buildPoint(tr('welcome.point1'), Colors.white, font),
                _buildPoint(tr('welcome.point2'), Colors.white, font),
                _buildPoint(tr('welcome.point3'), Colors.white, font),
                _buildPoint(tr('welcome.point4'), Colors.white, font),
                _buildPoint(tr('welcome.point5'), Colors.white, font),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  // 🚀 CTA Button (styled like VitalityFabButton with soft shadow)
  // --------------------------------------------------------------------------
  Widget _buildCta(AppPalette palette, double scale) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: 250 * scale,
        child: Material(
          elevation: 6, // 🌙 delikatny, ale widoczny cień
          shadowColor: palette.shadow.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(30 * scale),
          child: ElevatedButton(
            onPressed: () => _goNext(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.buttonPrimary,
              foregroundColor: palette.textTertiary,
              elevation: 0, // cień przejmuje Material
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30 * scale),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 24 * scale,
                vertical: 14 * scale,
              ),
              textStyle: AppTextStyles.button(
                palette.textTertiary,
              ).copyWith(fontSize: 15 * scale),
            ),
            child: Text(
              tr('welcome.cta'),
              style: AppTextStyles.button(
                palette.textTertiary,
              ).copyWith(fontSize: 15 * scale, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 🧱 Build
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final scale = width / 390;
    final padding = (width * 0.06).clamp(16.0, 28.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: _gradient(palette)),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(context, width, palette),
                            const SizedBox(height: 8),
                            _buildBenefits(palette, width),
                            Transform.translate(
                              offset: const Offset(0, 75),
                              child: _buildCta(palette, scale),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
