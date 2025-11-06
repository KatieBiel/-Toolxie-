// ============================================================================
// 🔔 NOTIFICATIONS SERVICE — Toolxie 2025 (Local Notifications, POLISHED)
// Android + iOS, daily/weekly/monthly repeats, graceful Exact Alarm handling
// - No intrusive settings redirect on every save
// - Falls back to inexact when needed
// - Exposes a one-shot "suggest exact alarm" flag for your UI popup
// Tested on Android 14 / iOS 17
// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:toolxie/data/database.dart'; // ✅ dodane

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // 👉 One-shot memory flag (per app session) to avoid nagging the user.
  static bool _askedExactOnceThisSession = false;

  // 👉 Exposed latch for UI: when true, you *may* show a gentle popup
  // suggesting the user to enable "Exact alarms" (Android 13+).
  static bool shouldSuggestExactAlarm = false;

  // =========================================================================
  // 🧭 Init helpers
  // =========================================================================
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    debugPrint('🔔 [Init] Initializing local notifications...');
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);

    final result = await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        debugPrint('🟢 [Tap] Notification tapped: ${resp.payload}');
      },
    );

    // Android channel
    final androidPlugin =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'toolxie_channel',
          'Toolxie Reminders',
          description: 'General reminders and scheduled notifications',
          importance: Importance.high,
        ),
      );
      debugPrint('✅ [Init] Android notification channel created.');
    } else {
      debugPrint('⚠️ [Init] Android notifications implementation not found.');
    }

    _initialized = true;
    debugPrint('✅ [Init] Local notifications ready. Result: $result');
  }

  // Public init (if you still call it directly in main)
  static Future<void> init() => _ensureInitialized();

  // =========================================================================
  // 🔐 Permissions
  // =========================================================================
  static Future<bool> requestPermission() async {
    await _ensureInitialized();

    debugPrint('🔑 [Permission] Checking notification permission...');
    final status = await Permission.notification.status;
    if (status.isGranted) {
      debugPrint('✅ [Permission] Already granted.');
      return true;
    }

    final result = await Permission.notification.request();
    if (result.isGranted) {
      debugPrint('✅ [Permission] Granted after request.');
      return true;
    }

    debugPrint('❌ [Permission] Denied or restricted: $result');
    return false;
  }

  // Check Exact Alarm (Android only). Never opens settings here.
  static Future<bool> _isExactAlarmGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      // Be permissive on unexpected platforms/ROMs
      debugPrint('⚠️ [ExactAlarm] Status check failed: $e — assuming allowed.');
      return true;
    }
  }

  // Optional helper you can call from your popup button:
  // Opens system settings so the user can enable Exact Alarms.
  static Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    try {
      final ok = await openAppSettings();
      debugPrint('⚙️ [ExactAlarm] Opened app settings: $ok');
    } catch (e) {
      debugPrint('⚠️ [ExactAlarm] Failed to open settings: $e');
    }
  }

  // =========================================================================
  // 💬 Instant notification (debug/test)
  // =========================================================================
  static Future<void> showNow({
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();

    debugPrint('📤 [ShowNow] Show: "$title"');
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'toolxie_channel',
        'Toolxie Reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.show(0, title, body, details);
      debugPrint('✅ [ShowNow] Displayed.');
    } catch (e) {
      debugPrint('❌ [ShowNow] Error: $e');
    }
  }

  // =========================================================================
  // 🕒 Schedule notification (daily/weekly/monthly)
  // - Uses exact when allowed; otherwise falls back to inexact.
  // - Sets a one-shot "shouldSuggestExactAlarm" for your UI (Android 13+).
  // =========================================================================
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    bool repeatDaily = false,
    bool repeatWeekly = false,
    bool repeatMonthly = false,
  }) async {
    await _ensureInitialized();

    debugPrint(
      '🗓️ [Schedule] ($id) "$title" → ${time.toLocal()} '
      '[daily=$repeatDaily, weekly=$repeatWeekly, monthly=$repeatMonthly]',
    );

    // 1) Notifications permission (iOS + Android)
    final allowed = await requestPermission();
    if (!allowed) {
      debugPrint('🔕 [Schedule] Permission denied. Aborting.');
      return;
    }

    // 2) Exact vs inexact
    bool exactAllowed = await _isExactAlarmGranted();

    // If not exact and we haven’t suggested yet this session → set UI flag
    if (!exactAllowed && !_askedExactOnceThisSession && Platform.isAndroid) {
      shouldSuggestExactAlarm = true; // UI may show a gentle popup once
      _askedExactOnceThisSession = true;
      debugPrint(
        '💡 [Schedule] Exact alarms not granted. '
        'Set shouldSuggestExactAlarm=true (one-shot).',
      );
    }

    // 3) Repeat component
    DateTimeComponents? repeatComponent;
    if (repeatDaily) repeatComponent = DateTimeComponents.time;
    if (repeatWeekly) repeatComponent = DateTimeComponents.dayOfWeekAndTime;
    if (repeatMonthly) repeatComponent = DateTimeComponents.dayOfMonthAndTime;

    // 4) Zoned time
    final scheduledDate = tz.TZDateTime.from(time, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'toolxie_channel',
        'Toolxie Reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(),
    );

    // 5) Schedule with fallback
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode:
            exactAllowed
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeatComponent,
        payload: 'time:${time.toIso8601String()}', // 💾 zapis godziny
      );

      // 💾 Save to local SQLite
      try {
        await AppDatabase.instance.upsertNotification(
          LocalNotification(
            id: id,
            title: title,
            body: body,
            hour: time.hour,
            minute: time.minute,
            frequency:
                repeatDaily
                    ? 'daily'
                    : repeatWeekly
                    ? 'weekly'
                    : repeatMonthly
                    ? 'monthly'
                    : 'once',
            weekday:
                repeatWeekly
                    ? [
                      'monday',
                      'tuesday',
                      'wednesday',
                      'thursday',
                      'friday',
                      'saturday',
                      'sunday',
                    ][time.weekday - 1]
                    : null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        debugPrint('💾 [Schedule] Saved notification to SQLite.');
      } catch (e) {
        debugPrint('⚠️ [Schedule] Failed to save notification locally: $e');
      }

      debugPrint(
        '✅ [Schedule] Scheduled id=$id at $scheduledDate '
        '(repeat=$repeatComponent, exact=$exactAllowed)',
      );
    } on PlatformException catch (e) {
      // If plugin throws because exact not allowed, retry in inexact mode.
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint(
          '⚠️ [Schedule] Exact not permitted. Retrying in inexact mode...',
        );
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: repeatComponent,
            payload: 'time:${time.toIso8601String()}', // 💾 zapis godziny
          );

          // 💾 Save to local SQLite also for fallback
          try {
            await AppDatabase.instance.upsertNotification(
              LocalNotification(
                id: id,
                title: title,
                body: body,
                hour: time.hour,
                minute: time.minute,
                frequency:
                    repeatDaily
                        ? 'daily'
                        : repeatWeekly
                        ? 'weekly'
                        : repeatMonthly
                        ? 'monthly'
                        : 'once',
                weekday:
                    repeatWeekly
                        ? [
                          'monday',
                          'tuesday',
                          'wednesday',
                          'thursday',
                          'friday',
                          'saturday',
                          'sunday',
                        ][time.weekday - 1]
                        : null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            debugPrint(
              '💾 [Schedule] Saved notification (fallback) to SQLite.',
            );
          } catch (e2) {
            debugPrint('⚠️ [Schedule] Fallback local save failed: $e2');
          }

          debugPrint('✅ [Schedule] Scheduled (inexact fallback).');
        } catch (e2) {
          debugPrint('❌ [Schedule] Fallback failed: $e2');
        }
      } else {
        debugPrint('❌ [Schedule] Failed: $e');
      }
    } catch (e) {
      debugPrint('❌ [Schedule] Unexpected error: $e');
    }
  }

  // =========================================================================
  // ❌ Cancel
  // =========================================================================
  static Future<void> cancel(int id) async {
    await _ensureInitialized();
    debugPrint('🗑️ [Cancel] id=$id');
    try {
      await _plugin.cancel(id);
      debugPrint('✅ [Cancel] Done.');
    } catch (e) {
      debugPrint('❌ [Cancel] Error: $e');
    }
  }

  static Future<void> cancelAll() async {
    await _ensureInitialized();
    debugPrint('🗑️ [CancelAll] All');
    try {
      await _plugin.cancelAll();
      debugPrint('✅ [CancelAll] Done.');
    } catch (e) {
      debugPrint('❌ [CancelAll] Error: $e');
    }
  }

  // =========================================================================
  // 🧾 List pending (for SettingsPage summary)
  // =========================================================================
  static Future<List<PendingNotificationRequest>> list() async {
    await _ensureInitialized();
    debugPrint('📋 [List] Fetching pending notifications...');
    try {
      final list = await _plugin.pendingNotificationRequests();
      debugPrint('📊 [List] ${list.length} pending:');
      for (final n in list) {
        debugPrint('  • ID ${n.id}: "${n.title}" — ${n.body}');
      }
      return list;
    } catch (e) {
      debugPrint('❌ [List] Error: $e');
      return [];
    }
  }
}
