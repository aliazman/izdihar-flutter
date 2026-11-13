import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izdihar/models/session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Three daily sessions contain all 116 authored items', () async {
    final decoded = jsonDecode(await rootBundle.loadString('assets/content.json')) as List;
    final sessions = decoded.map((item) => Session.fromJson(Map<String, dynamic>.from(item))).toList();
    expect(sessions.map((s) => s.id), ['morning', 'evening', 'night']);
    expect(sessions.length, 3);
    expect(sessions.fold<int>(0, (n, s) => n + s.totalEntries), 116);
    for (final session in sessions) {
      expect(session.quran.keys.toList(), ['rizq', 'love', 'success', 'status']);
      expect(session.entries.map((e) => e.id).toSet().length, session.totalEntries);
      expect(session.entries.any((e) => e.isVerse), isTrue);
    }
  });
}
