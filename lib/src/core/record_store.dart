import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cognata.dart';
import 'models.dart';

class RecordStore {
  static const _storageKey = 'cognata-record-v1';

  Future<DailyRecord?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return null;
      return DailyRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(DailyRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(record.toJson()));
    } catch (_) {
      // Storage unavailable — ignore, like the web app's private-mode fallback.
    }
  }

  /// Record a finished game and update the streak.
  Future<DailyRecord> recordResult(int guessesUsed, [DateTime? date]) async {
    final d = date ?? DateTime.now();
    final key = todayKey(d);
    final prev = await load() ?? DailyRecord.empty;
    if (prev.results[key] != null) return prev;

    final yesterday = d.toUtc().subtract(const Duration(days: 1));
    final playedYesterday = prev.results[todayKey(yesterday)] != null;
    final streak = playedYesterday ? prev.streak + 1 : 1;

    final record = DailyRecord(
      lastPlayed: key,
      streak: streak,
      results: {...prev.results, key: guessesUsed},
    );
    await save(record);
    return record;
  }
}
