import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  static Future<void> cancelAll() {
    if (kIsWeb) return Future.value();
    return _plugin.cancelAll();
  }

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'segunda_vida_daily',
          'Recordatorios Diarios',
          channelDescription: 'Notificaciones de Segunda Vida',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // Pre-configured notification schedules
  static const int waterId = 100;
  static const int habitsId = 101;
  static const int sleepId = 102;

  static Future<void> scheduleWaterReminder(int hour, int minute) => scheduleDaily(
    id: waterId,
    title: '💧 Hora de hidratarse',
    body: '¿Ya tomaste agua? Recuerda mantener tu meta diaria.',
    hour: hour,
    minute: minute,
  );

  static Future<void> scheduleHabitsReminder(int hour, int minute) => scheduleDaily(
    id: habitsId,
    title: '✅ Revisa tus hábitos',
    body: 'Es momento de completar tus hábitos del día.',
    hour: hour,
    minute: minute,
  );

  static Future<void> scheduleSleepReminder(int hour, int minute) => scheduleDaily(
    id: sleepId,
    title: '😴 Hora de descansar',
    body: 'Prepárate para dormir y cumplir tu meta de sueño.',
    hour: hour,
    minute: minute,
  );

  static Future<void> cancelNotification(int id) {
    if (kIsWeb) return Future.value();
    return _plugin.cancel(id);
  }
}

// Hive keys for notification preferences
const _kNotifWaterEnabled = 'notif_water_enabled';
const _kNotifWaterHour = 'notif_water_hour';
const _kNotifWaterMinute = 'notif_water_minute';
const _kNotifHabitsEnabled = 'notif_habits_enabled';
const _kNotifHabitsHour = 'notif_habits_hour';
const _kNotifHabitsMinute = 'notif_habits_minute';
const _kNotifSleepEnabled = 'notif_sleep_enabled';
const _kNotifSleepHour = 'notif_sleep_hour';
const _kNotifSleepMinute = 'notif_sleep_minute';

class NotificationPrefs {
  static Box get _box => Hive.box(AppConstants.settingsBox);

  static bool get waterEnabled => _box.get(_kNotifWaterEnabled, defaultValue: false) as bool;
  static int get waterHour => _box.get(_kNotifWaterHour, defaultValue: 8) as int;
  static int get waterMinute => _box.get(_kNotifWaterMinute, defaultValue: 0) as int;

  static bool get habitsEnabled => _box.get(_kNotifHabitsEnabled, defaultValue: false) as bool;
  static int get habitsHour => _box.get(_kNotifHabitsHour, defaultValue: 20) as int;
  static int get habitsMinute => _box.get(_kNotifHabitsMinute, defaultValue: 0) as int;

  static bool get sleepEnabled => _box.get(_kNotifSleepEnabled, defaultValue: false) as bool;
  static int get sleepHour => _box.get(_kNotifSleepHour, defaultValue: 22) as int;
  static int get sleepMinute => _box.get(_kNotifSleepMinute, defaultValue: 30) as int;

  static Future<void> setWater(bool enabled, int hour, int minute) async {
    await _box.put(_kNotifWaterEnabled, enabled);
    await _box.put(_kNotifWaterHour, hour);
    await _box.put(_kNotifWaterMinute, minute);
    if (enabled) {
      await NotificationService.scheduleWaterReminder(hour, minute);
    } else {
      await NotificationService.cancelNotification(NotificationService.waterId);
    }
  }

  static Future<void> setHabits(bool enabled, int hour, int minute) async {
    await _box.put(_kNotifHabitsEnabled, enabled);
    await _box.put(_kNotifHabitsHour, hour);
    await _box.put(_kNotifHabitsMinute, minute);
    if (enabled) {
      await NotificationService.scheduleHabitsReminder(hour, minute);
    } else {
      await NotificationService.cancelNotification(NotificationService.habitsId);
    }
  }

  static Future<void> setSleep(bool enabled, int hour, int minute) async {
    await _box.put(_kNotifSleepEnabled, enabled);
    await _box.put(_kNotifSleepHour, hour);
    await _box.put(_kNotifSleepMinute, minute);
    if (enabled) {
      await NotificationService.scheduleSleepReminder(hour, minute);
    } else {
      await NotificationService.cancelNotification(NotificationService.sleepId);
    }
  }
}

final notifPrefsProvider = StateProvider<int>((ref) => 0); // trigger rebuild
