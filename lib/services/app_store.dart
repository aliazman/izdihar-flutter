import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';
import 'reminder_service.dart';

String dayId(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class AppStore extends ChangeNotifier {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final ReminderService reminder = ReminderService();
  List<Session> sessions = [];
  Set<String> readItems = {};
  Set<String> finishedSessions = {};
  Set<String> favorites = {};
  List<int> times = [7 * 60, 17 * 60 + 30, 22 * 60];
  int snoozeMinutes = 45;
  bool remindersOn = true;
  bool ready = false;
  String? notificationError;

  Future<void> initialize() async {
    final source = await rootBundle.loadString('assets/content.json');
    sessions = (jsonDecode(source) as List)
        .map((e) => Session.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    readItems = (await _prefs.getStringList('read_entries') ?? []).toSet();
    finishedSessions = (await _prefs.getStringList('finished_sessions') ?? []).toSet();
    favorites = (await _prefs.getStringList('favorites') ?? []).toSet();
    times = (await _prefs.getStringList('times') ?? ['420', '1050', '1320'])
        .map((e) => int.tryParse(e) ?? 420).toList();
    if (times.length != 3) times = [420, 1050, 1320];
    snoozeMinutes = await _prefs.getInt('snooze') ?? 45;
    remindersOn = await _prefs.getBool('reminders') ?? true;
    ready = true;
    notifyListeners();
    try {
      await reminder.initialize();
      if (remindersOn) await reminder.requestPermission();
      await refreshReminders();
    } catch (error) {
      notificationError = 'تعذر إعداد التنبيهات على هذا الجهاز: $error';
      notifyListeners();
    }
  }

  String _readKey(String entryId, [DateTime? date]) => '${dayId(date ?? DateTime.now())}|$entryId';
  String _finishedKey(String sessionId, [DateTime? date]) => '${dayId(date ?? DateTime.now())}|$sessionId';

  bool isRead(String entryId, [DateTime? date]) => readItems.contains(_readKey(entryId, date));
  bool isFinished(String sessionId, [DateTime? date]) => finishedSessions.contains(_finishedKey(sessionId, date));
  bool isFavorite(String entryId) => favorites.contains(entryId);

  int countRead(Session session, [DateTime? date]) => session.entries
      .where((entry) => isRead(entry.id, date))
      .length;

  double ratio(Session session, [DateTime? date]) =>
      session.totalEntries == 0 ? 0 : countRead(session, date) / session.totalEntries;

  int completedToday() => sessions.where((s) => isFinished(s.id)).length;

  int get streak {
    final now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day);
    // A streak is based on completion of all three sessions per day.
    if (!sessions.every((s) => isFinished(s.id, start))) {
      start = start.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (count < 3650 && sessions.every((s) => isFinished(s.id, start))) {
      count++;
      start = start.subtract(const Duration(days: 1));
    }
    return count;
  }

  int get totalCompleteDays {
    final days = finishedSessions.map((e) => e.split('|').first).toSet();
    return days.where((day) => sessions.every((s) => finishedSessions.contains('$day|${s.id}'))).length;
  }

  Future<void> toggleRead(String entryId) async {
    final key = _readKey(entryId);
    if (!readItems.add(key)) {
      readItems.remove(key);
      // If a previously finished session was edited, keep the intentional
      // session-finish flag; users can explicitly undo that flag separately.
    }
    notifyListeners();
    await _prefs.setStringList('read_entries', readItems.toList());
  }

  Future<void> toggleFavorite(String entryId) async {
    if (!favorites.add(entryId)) favorites.remove(entryId);
    notifyListeners();
    await _prefs.setStringList('favorites', favorites.toList());
  }

  Future<void> setFinished(String sessionId, bool completed) async {
    final key = _finishedKey(sessionId);
    if (completed) {
      finishedSessions.add(key);
    } else {
      finishedSessions.remove(key);
    }
    notifyListeners();
    await _prefs.setStringList('finished_sessions', finishedSessions.toList());
    try {
      if (remindersOn) {
        if (completed) {
          final index = sessions.indexWhere((s) => s.id == sessionId);
          await reminder.cancelSessionForDate(DateTime.now(), index);
        } else {
          await refreshReminders();
        }
      }
    } catch (error) {
      notificationError = 'تعذر تحديث التذكيرات: $error';
      notifyListeners();
    }
  }

  Future<void> updateTime(int sessionIndex, int minutes) async {
    times[sessionIndex] = minutes;
    notifyListeners();
    await _prefs.setStringList('times', times.map((e) => '$e').toList());
    await refreshReminders();
  }

  Future<void> updateSnooze(int value) async {
    snoozeMinutes = value;
    notifyListeners();
    await _prefs.setInt('snooze', value);
    await refreshReminders();
  }

  Future<void> setReminders(bool value) async {
    remindersOn = value;
    notifyListeners();
    await _prefs.setBool('reminders', value);
    try {
      if (value) await reminder.requestPermission();
      await refreshReminders();
    } catch (error) {
      notificationError = 'تعذر تشغيل التذكيرات: $error';
      notifyListeners();
    }
  }

  Future<void> refreshReminders() async {
    try {
      await reminder.scheduleRollingWindow(
        times: times,
        retryMinutes: snoozeMinutes,
        enabled: remindersOn,
        isFinished: isFinished,
        sessionIds: sessions.map((s) => s.id).toList(),
      );
      notificationError = null;
      notifyListeners();
    } catch (error) {
      notificationError = 'تعذر جدولة التنبيهات: $error';
      notifyListeners();
    }
  }
}
