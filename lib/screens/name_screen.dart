// lib/screens/name_screen.dart
// ============================================================================
// 🪞 Name Screen – user enters their name after welcome
// Refactor goals (2025):
// - Fully themed via AppPalette (no AppColors)
// - Responsive & accessible
// - Shared styles from AppTextStyles / AppButtonStyles
// - Async-safe navigation & loading state
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:toolxie/common/router.dart';
import 'package:toolxie/common/theme.dart';
import 'package:toolxie/data/providers.dart';

class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final TextEditingController controller = TextEditingController();
  bool _saving = false;

  // --------------------------------------------------------------------------
  // 💾 Save and navigate
  // --------------------------------------------------------------------------
  Future<void> _submit() async {
    final name = controller.text.trim();
    final palette = ref.watch(currentPaletteProvider);

    // 🚫 Walidacja pustego imienia
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('name.validation_empty'),
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              Colors.white,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          backgroundColor: palette.pink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }

    if (_saving) return;
    setState(() => _saving = true);

    try {
      await ref.read(userNameProvider.notifier).setName(name);
      if (!mounted) return;

      FocusScope.of(context).unfocus();
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } catch (e) {
      debugPrint('❌ Error saving name: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: palette.buttonPrimary,
          content: Text(
            tr('name.error_generic'),
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              Colors.white,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // 🧱 Build
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final size = MediaQuery.sizeOf(context);
    final width = size.width.clamp(320.0, 600.0);
    final scale = size.width / 390;
    final textColor = palette.text;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.green, palette.turquoise],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: width,
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppShadows.soft(palette.shadow),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ----------------------------------------------------------
                    // 🌿 Logo
                    // ----------------------------------------------------------
                    Image.asset(
                      'assets/images/icons/logo_bg.webp',
                      height: (width * 0.4).clamp(120.0, 180.0),
                    ),
                    const SizedBox(height: 16),

                    // ----------------------------------------------------------
                    // 🧩 Title
                    // ----------------------------------------------------------
                    Text(
                      tr('name.title'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title(textColor).copyWith(
                        fontSize: 26 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 18 * scale),

                    // ----------------------------------------------------------
                    // ✍️ Input Field
                    // ----------------------------------------------------------
                    NameField(
                      controller: controller,
                      onSubmit: _submit,
                      color: textColor,
                      scale: scale,
                    ),

                    SizedBox(height: 10 * scale),

                    // ----------------------------------------------------------
                    // 💬 Info
                    // ----------------------------------------------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        tr('name.info1'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                          textColor,
                        ).copyWith(fontSize: 18 * scale, height: 1.4),
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    Text(
                      tr('name.info2'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.small(textColor).copyWith(
                        fontSize: 15 * scale,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    SizedBox(height: 36 * scale),

                    // ----------------------------------------------------------
                    // 🚀 Submit Button
                    // ----------------------------------------------------------
                    SubmitButton(
                      saving: _saving,
                      onPressed: _submit,
                      palette: palette,
                      scale: scale,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🔤 NameField – input with themed underline
// ============================================================================
class NameField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final Color color;
  final double scale;

  const NameField({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.color,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fieldWidth = (width * 0.75).clamp(260.0, 340.0);

    return SizedBox(
      width: fieldWidth,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.givenName],
        autofocus: true,
        onSubmitted: (_) => onSubmit(),
        maxLength: 20,
        cursorColor: color,
        style: AppTextStyles.title(
          color,
        ).copyWith(fontSize: 20 * scale, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: tr('name.hint'),
          hintStyle: AppTextStyles.body(
            color.withValues(alpha: 0.5),
          ).copyWith(fontSize: 20 * scale, fontWeight: FontWeight.w600),
          counterStyle: AppTextStyles.small(color.withValues(alpha: 0.6)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: color.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🔘 SubmitButton – themed primary button (same style as VitalityFabButton)
// ============================================================================
class SubmitButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onPressed;
  final AppPalette palette;
  final double scale;

  const SubmitButton({
    super.key,
    required this.saving,
    required this.onPressed,
    required this.palette,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160 * scale,
      child: ElevatedButton(
        onPressed: saving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.buttonPrimary,
          foregroundColor: palette.textTertiary,
          shadowColor: palette.shadow,
          elevation: 3,
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
        child:
            saving
                ? SizedBox(
                  height: 18 * scale,
                  width: 18 * scale,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    color: palette.textTertiary,
                  ),
                )
                : Text(
                  tr('name.next'),
                  style: AppTextStyles.button(
                    palette.textTertiary,
                  ).copyWith(fontSize: 15 * scale, fontWeight: FontWeight.w700),
                ),
      ),
    );
  }
}
