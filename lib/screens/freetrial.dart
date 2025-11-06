// lib/screens/freetrial.dart
// ============================================================================
// 🆓 FREE TRIAL POPUP — Toolxie 2025 FINAL
// ----------------------------------------------------------------------------
// - Identical look to PaywallScreen (pastel rounded dialog)
// - Golden crown instead of gradient icon
// - Used when user clicks on premium tool without active subscription
// ============================================================================

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toolxie/common/theme.dart';
import 'package:toolxie/data/database.dart';
import 'package:toolxie/data/providers.dart';
import 'package:toolxie/screens/paywall.dart';

class FreeTrialScreen extends ConsumerWidget {
  final bool trialExpired; // true if trial is over

  const FreeTrialScreen({super.key, this.trialExpired = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    final scale = MediaQuery.of(context).size.width / 390;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 28 * scale),
      child: Container(
        padding: EdgeInsets.all(24 * scale),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(36 * scale),
          boxShadow: AppShadows.soft(palette.shadow),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 👑 Golden crown icon
              Container(
                padding: EdgeInsets.all(18 * scale),
                child: Icon(
                  FontAwesomeIcons.crown,
                  size: 35 * scale,
                  color: palette.gold,
                ),
              ),

              // 🏷️ Title
              Text(
                trialExpired
                    ? tr('freetrial.expired_title')
                    : tr('freetrial.title'),
                textAlign: TextAlign.center,
                style: AppTextStyles.title(
                  palette.text,
                ).copyWith(fontSize: 22 * scale, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12 * scale),

              // 📖 Description
              Text(
                trialExpired
                    ? tr('freetrial.expired_subtitle')
                    : tr('freetrial.subtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  palette.text,
                ).copyWith(fontSize: 15 * scale, height: 1.5),
              ),
              SizedBox(height: 26 * scale),

              // 🎁 Main action button
              FilledButton(
                style: AppButtonStyles.primary(palette.buttonPrimary).copyWith(
                  minimumSize: WidgetStatePropertyAll(
                    Size(double.infinity, 50 * scale),
                  ),
                  alignment: Alignment.center, // ✅ wymusza wyśrodkowanie napisu
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30 * scale),
                    ),
                  ),
                ),
                onPressed: () async {
                  if (trialExpired) {
                    // 🔒 Trial już się skończył → otwórz paywall
                    Navigator.pop(context);
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (_) => const PaywallScreen(),
                    );
                  } else {
                    // 🆓 Rozpocznij darmowy okres próbny (14 dni)
                    await AppDatabase.instance.startFreeTrial(days: 14);
                    ref.invalidate(subscriptionActiveProvider);
                    ref.invalidate(premiumStatusProvider);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr('freetrial.started_snackbar')),
                        duration: const Duration(seconds: 3),
                      ),
                    );

                    // ✅ ZAMKNIJ popup (tylko raz)
                    Navigator.pop(context, 'trial_started');
                  }
                },

                child: Center(
                  child: Text(
                    trialExpired
                        ? tr('freetrial.open_paywall_button')
                        : tr('freetrial.start_button'),
                    textAlign:
                        TextAlign.center, // ✅ dodatkowo dla bezpieczeństwa
                    style: AppTextStyles.body(Colors.white).copyWith(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24 * scale),

              // ─────────────── Divider ───────────────
              Divider(
                color: palette.text.withValues(alpha: 0.15),
                thickness: 1,
                height: 20 * scale,
              ),
              SizedBox(height: 8 * scale),

              // 📜 Info
              Text(
                tr('freetrial.info'),
                textAlign: TextAlign.center,
                style: AppTextStyles.small(
                  palette.text.withValues(alpha: 0.6),
                ).copyWith(fontSize: 12 * scale),
              ),
              SizedBox(height: 12 * scale),

              // ❌ Close button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  tr('freetrial.close_button'),
                  style: AppTextStyles.body(
                    palette.accent,
                  ).copyWith(fontSize: 14 * scale, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
