// lib/screens/splash_page.dart
// ============================================================================
// 🚀 Splash Screen – animated intro before routing to start page
// Refactor goals (2025):
// - Responsive (MediaQuery scaling)
// - All colors + text styles from theme
// - Translations from JSON only (no hardcoded text)
// - Animation sequence fully async-safe
// - Max ~500 lines, modular & clean
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:toolxie/common/theme.dart';
import 'package:toolxie/common/router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // 🕒 Animation Durations
  // --------------------------------------------------------------------------
  static const _logoDuration = Duration(milliseconds: 1000);
  static const _titleDuration = Duration(milliseconds: 1000);
  static const _taglineDuration = Duration(milliseconds: 1000);

  // --------------------------------------------------------------------------
  // 🎬 Animation Controllers
  // --------------------------------------------------------------------------
  late final AnimationController _logoCtl;
  late final AnimationController _titleCtl;
  late final AnimationController _taglineCtl;

  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineFade;

  // --------------------------------------------------------------------------
  // 🖼️ Logo
  // --------------------------------------------------------------------------
  final _logoProvider = const AssetImage('assets/images/icons/logo_bg.webp');
  bool _logoReady = false;

  // --------------------------------------------------------------------------
  // 🔧 Init
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _logoCtl = AnimationController(vsync: this, duration: _logoDuration);
    _titleCtl = AnimationController(vsync: this, duration: _titleDuration);
    _taglineCtl = AnimationController(vsync: this, duration: _taglineDuration);

    _logoSlide = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoCtl, curve: Curves.easeOutCubic));

    _logoFade = CurvedAnimation(
      parent: _logoCtl,
      curve: const Interval(0.2, 1.0),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _titleCtl, curve: Curves.easeOutCubic));

    _titleFade = CurvedAnimation(
      parent: _titleCtl,
      curve: const Interval(0.15, 1.0),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _taglineCtl, curve: Curves.easeOutCubic));

    _taglineFade = CurvedAnimation(
      parent: _taglineCtl,
      curve: const Interval(0.15, 1.0),
    );
  }

  // --------------------------------------------------------------------------
  // 🖼️ Preload logo & start animation
  // --------------------------------------------------------------------------
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_logoProvider, context).whenComplete(() {
      if (!mounted) return;
      setState(() => _logoReady = true);
      _startSequence();
    });
  }

  // --------------------------------------------------------------------------
  // 🎞️ Animation sequence logic
  // --------------------------------------------------------------------------
  void _startSequence() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logoCtl.forward();
      _logoCtl.addStatusListener((status) {
        if (status == AnimationStatus.completed) _titleCtl.forward();
      });
      _titleCtl.addStatusListener((status) {
        if (status == AnimationStatus.completed) _taglineCtl.forward();
      });
      _taglineCtl.addStatusListener((status) async {
        if (status == AnimationStatus.completed && mounted) {
          await Future.delayed(const Duration(milliseconds: 600));
          try {
            final next = await AppRouter.decideStartRoute(ref);
            if (mounted) Navigator.pushReplacementNamed(context, next);
          } catch (e) {
            debugPrint('Routing error: $e');
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRouter.welcome);
            }
          }
        }
      });
    });
  }

  // --------------------------------------------------------------------------
  // 🧹 Cleanup
  // --------------------------------------------------------------------------
  @override
  void dispose() {
    _logoCtl.dispose();
    _titleCtl.dispose();
    _taglineCtl.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // 🎨 Helpers: Gradient & text color per theme
  // --------------------------------------------------------------------------
  LinearGradient _gradient(AppPalette palette) => palette.backgroundGradient;
  Color _textColor(AppPalette palette) => palette.text;

  // --------------------------------------------------------------------------
  // 🧱 Build
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;

    // Responsive scaling
    final double logoWidth = (size.width * 0.8).clamp(220.0, 480.0);
    const logoAspect = 0.6;
    final double titleFont = (shortest * 0.085).clamp(26.0, 36.0);
    final double taglineFont = (shortest * 0.05).clamp(18.0, 24.0);
    final double vGap = (shortest * 0.06).clamp(16.0, 32.0);
    final double lift = (shortest * 0.08);
    final Color color = _textColor(palette);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedOpacity(
        opacity: _logoReady ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: Container(
          decoration: BoxDecoration(gradient: _gradient(palette)),
          child: SafeArea(
            child: Center(
              child: Transform.translate(
                offset: Offset(0, -lift),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ----------------------------------------------------------
                      // 🧩 LOGO
                      // ----------------------------------------------------------
                      SizedBox(
                        width: logoWidth,
                        height: logoWidth * logoAspect,
                        child:
                            _logoReady
                                ? FadeTransition(
                                  opacity: _logoFade,
                                  child: SlideTransition(
                                    position: _logoSlide,
                                    child: Image(
                                      image: _logoProvider,
                                      filterQuality: FilterQuality.high,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                                : const SizedBox.shrink(),
                      ),
                      SizedBox(height: vGap),

                      // ----------------------------------------------------------
                      // 🔤 TITLE
                      // ----------------------------------------------------------
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: Text(
                            tr('splash.title'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.title(color).copyWith(
                              fontSize: titleFont,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: vGap * 0.8),

                      // ----------------------------------------------------------
                      // 💬 TAGLINE
                      // ----------------------------------------------------------
                      FadeTransition(
                        opacity: _taglineFade,
                        child: SlideTransition(
                          position: _taglineSlide,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  24.0 * (shortest / 390).clamp(0.8, 1.4),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                tr('splash.tagline'),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.subtitle(color).copyWith(
                                  fontSize: taglineFont,
                                  letterSpacing: 0.8,
                                  color: color.withValues(alpha: 0.9),
                                ),
                              ),
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
      ),
    );
  }
}
