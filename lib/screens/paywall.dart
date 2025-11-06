// lib/screens/paywall.dart
// ============================================================================
// 💎 PAYWALL SCREEN — Toolxie 2025 FINAL (with Divider, Scroll Safe & Billing)
// ----------------------------------------------------------------------------
// - Handles Google Play / App Store purchases
// - Activates local + Firebase subscription
// - Runs full sync after confirmed purchase
// ============================================================================

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:toolxie/common/theme.dart';
import 'package:toolxie/data/database.dart';
import 'package:toolxie/data/providers.dart';

// 🔥 Firebase & Auth
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toolxie/data/auth_service.dart';
import 'package:toolxie/main.dart';

// ============================================================================
// 💳 PURCHASE SERVICE (inline, for simplicity)
// ============================================================================
class PurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static const List<String> _kProductIds = ['30_premium', '365_premium'];

  static Future<void> init() async {
    final available = await _iap.isAvailable();
    debugPrint('💰 In-App Purchase available: $available');
  }

  static Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(_kProductIds.toSet());
    if (response.error != null) {
      debugPrint('⚠️ Error fetching products: ${response.error}');
      return [];
    }
    return response.productDetails;
  }

  static Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }
}

// ============================================================================
// 💎 PAYWALL SCREEN
// ============================================================================
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    final scale = MediaQuery.of(context).size.width / 390;

    // ========================================================================
    // 🧭 PURCHASE LISTENER — aktywuje premium dopiero po potwierdzonym zakupie
    // ========================================================================
    final InAppPurchase iap = InAppPurchase.instance;
    iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          final type = purchase.productID;
          final expiry = type == '365_premium'
              ? DateTime.now().add(const Duration(days: 365))
              : DateTime.now().add(const Duration(days: 30));

          // 💾 Aktywacja subskrypcji lokalnie (SQLite)
          await AppDatabase.instance.activateSubscription(
            type: type,
            expiry: expiry,
          );

          // 🔥 Zaloguj do Firebase i zapisz status subskrypcji
          await ensureFirebaseInitialized();
          final auth = FirebaseAuth.instance;
          User? user = auth.currentUser;
          user ??= (await auth.signInAnonymously()).user;

          if (user != null) {
            final fs = FirebaseFirestore.instance;
            await fs.collection('users').doc(user.uid).set({
              'subscription': {
                'active': true,
                'type': type,
                'expiry': expiry.toIso8601String(),
                'activatedBy': 'purchase',
              },
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            // 🔗 Dodaj mapowanie recoveryCodes/{code} -> uid (dla odzyskiwania konta)
            final recoveryCode = await AppDatabase.instance.getRecoveryCode();
            if (recoveryCode != null && recoveryCode.isNotEmpty) {
              await fs.collection('recoveryCodes').doc(recoveryCode).set({
                'uid': user.uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }

            debugPrint('✅ Purchase synced to Firestore for ${user.uid}');

            // 🚀 Uruchom pełną synchronizację po zakupie
            await AuthService.activateFirebaseAfterVip();
          } else {
            debugPrint('❌ Firebase user is null — cannot sync');
          }

          await updateSubscriptionState(ref);
          ref.invalidate(premiumStatusProvider);
          ref.invalidate(hasPremiumAccessProvider);
          ref.read(subscriptionActiveProvider.notifier).state = true;

          await iap.completePurchase(purchase);

          // 🎉 UI feedback
          if (context.mounted) {
            final rootContext = Navigator.of(
              context,
              rootNavigator: true,
            ).context;
            final messenger = ScaffoldMessenger.maybeOf(rootContext);
            messenger?.showSnackBar(
              SnackBar(
                content: Text(
                  tr('paywall.success'),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: palette.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pop(context);
          }
        } else if (purchase.status == PurchaseStatus.error ||
            purchase.status == PurchaseStatus.canceled) {
          debugPrint('🚫 Purchase canceled or failed');
        }
      }
    });

    // ========================================================================
    // 🛒 PURCHASE HANDLER
    // ========================================================================
    Future<void> handlePurchase(String type) async {
      try {
        await PurchaseService.init();
        final products = await PurchaseService.loadProducts();

        final product = products.firstWhere(
          (p) => p.id == type,
          orElse: () => throw Exception('$type not found in Play Store'),
        );

        await PurchaseService.buy(product);
      } catch (e) {
        debugPrint('❌ Purchase failed for $type: $e');

        if (!context.mounted) return;
        final rootContext = Navigator.of(context, rootNavigator: true).context;
        final messenger = ScaffoldMessenger.maybeOf(rootContext);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              tr('paywall.error'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: palette.pink,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    // ========================================================================
    // 🎨 UI
    // ========================================================================
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
              Container(
                padding: EdgeInsets.all(18 * scale),

                child: Transform.translate(
                  offset: Offset(-2 * scale, 0),
                  child: Icon(
                    FontAwesomeIcons.crown,
                    size: 40 * scale,
                    color: palette.gold,
                  ),
                ),
              ),
              SizedBox(height: 20 * scale),

              Text(
                tr('paywall.title'),
                textAlign: TextAlign.center,
                style: AppTextStyles.title(
                  palette.text,
                ).copyWith(fontSize: 22 * scale, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12 * scale),

              Text(
                tr('paywall.subtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  palette.text,
                ).copyWith(fontSize: 15 * scale, height: 1.5),
              ),
              SizedBox(height: 26 * scale),

              FilledButton(
                style: AppButtonStyles.primary(palette.buttonPrimary).copyWith(
                  minimumSize: WidgetStatePropertyAll(
                    Size(double.infinity, 50 * scale),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30 * scale),
                    ),
                  ),
                ),
                onPressed: () => handlePurchase('30_premium'),
                child: Text(
                  tr('paywall.monthly_button'),
                  style: AppTextStyles.body(
                    Colors.white,
                  ).copyWith(fontSize: 15 * scale, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: 14 * scale),

              FilledButton(
                style: AppButtonStyles.primary(palette.buttonSecondary)
                    .copyWith(
                      minimumSize: WidgetStatePropertyAll(
                        Size(double.infinity, 50 * scale),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30 * scale),
                        ),
                      ),
                    ),
                onPressed: () => handlePurchase('365_premium'),
                child: Text(
                  tr('paywall.yearly_button'),
                  style: AppTextStyles.body(
                    Colors.white,
                  ).copyWith(fontSize: 15 * scale, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: 24 * scale),

              // ─────────────── Divider ───────────────
              Divider(
                color: palette.textPrimary,
                thickness: 1,
                height: 20 * scale,
              ),
              SizedBox(height: 8 * scale),

              Text(
                tr('paywall.info'),
                textAlign: TextAlign.center,
                style: AppTextStyles.small(
                  palette.text.withValues(alpha: 0.6),
                ).copyWith(fontSize: 12 * scale),
              ),
              SizedBox(height: 12 * scale),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  tr('paywall.close'),
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
