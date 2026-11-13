import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  void Function(String sessionId)? _onTap;
  String? _pendingSessionId;

  void attachNavigation(void Function(String sessionId) callback) {
    _onTap = callback;
    if (_pendingSessionId != null) {
      final id = _pendingSessionId!;
      _pendingSessionId = null;
      callback(id);
    }
  }

  void detachNavigation() => _onTap = null;

  void _notifyTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    if (_onTap != null) {
      _onTap!(payload);
    } else {
      _pendingSessionId = payload;
    }
  }

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'izdihar_daily_v1',
      'ازدهار • تذكير الجلسات',
      channelDescription: 'تذكير صباحي ومسائي وليلي، مع إعادة التذكير عند عدم إكمال الجلسة',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    ),
  );

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // Fall back to the OS-reported UTC offset if the IANA name is unavailable.
      // This cannot track future daylight-saving transitions; the schedule is
      // re-created at the next application launch.
      final offset = DateTime.now().timeZoneOffset;
      final wholeHours = offset.inHours;
      if (offset.inMinutes % 60 == 0 && wholeHours.abs() <= 14) {
        final sign = wholeHours >= 0 ? '-' : '+'; // Etc/GMT uses POSIX signs.
        tz.setLocalLocation(tz.getLocation('Etc/GMT$sign${wholeHours.abs()}'));
      } else {
        rethrow;
      }
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _notifyTap(response.payload),
    );
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      _notifyTap(details?.notificationResponse?.payload);
    }
  }

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  int _id(DateTime date, int index, bool retry) {
    final days = DateTime.utc(date.year, date.month, date.day)
            .difference(DateTime.utc(1970)).inDays;
    return days * 10 + index * 2 + (retry ? 1 : 0);
  }

  Future<void> cancelSessionForDate(DateTime date, int index) async {
    if (index < 0) return;
    await _plugin.cancel(id: _id(date, index, false));
    await _plugin.cancel(id: _id(date, index, true));
  }

  Future<void> scheduleRollingWindow({
    required List<int> times,
    required int retryMinutes,
    required bool enabled,
    required bool Function(String, DateTime) isFinished,
    required List<String> sessionIds,
  }) async {
    await _plugin.cancelAllPendingNotifications();
    if (!enabled) return;
    final now = tz.TZDateTime.now(tz.local);
    final names = ['الصباح', 'المساء', 'الليل'];
    for (var offset = 0; offset < 10; offset++) {
      final day = tz.TZDateTime(tz.local, now.year, now.month, now.day + offset);
      for (var index = 0; index < 3; index++) {
        if (isFinished(sessionIds[index], day)) continue;
        final time = tz.TZDateTime(
          tz.local, day.year, day.month, day.day,
          times[index] ~/ 60, times[index] % 60,
        );
        final retryAt = time.add(Duration(minutes: retryMinutes));
        if (time.isAfter(now)) {
          await _plugin.zonedSchedule(
            id: _id(day, index, false),
            title: 'حان موعد جلسة ${names[index]} ✨',
            body: 'لحظة قصيرة لنفسك. افتح ازدهار وسجّل توكيداتك المقروءة.',
            scheduledDate: time,
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: sessionIds[index],
          );
        }
        if (retryAt.isAfter(now)) {
          await _plugin.zonedSchedule(
            id: _id(day, index, true),
            title: 'لم تُكمل جلسة ${names[index]} بعد 💫',
            body: 'لا بأس إن انشغلت، يمكنك إكمال قراءتك الآن.',
            scheduledDate: retryAt,
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: sessionIds[index],
          );
        }
      }
    }
  }
}
