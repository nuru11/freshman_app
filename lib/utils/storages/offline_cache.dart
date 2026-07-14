import 'package:hive_flutter/hive_flutter.dart';
import 'package:vector_academy/models/models.dart';

class HiveNewsStorage {
  static const String _boxName = 'newsStorage';
  static const String _newsKey = 'news_items';
  static late Box<dynamic> _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<dynamic>(_boxName);
    } else {
      _box = Hive.box<dynamic>(_boxName);
    }
  }

  Future<void> setNews(List<News> news) async {
    final jsonList = news.map((item) => item.toJson()).toList();
    await _box.put(_newsKey, jsonList);
  }

  Future<List<News>> getNews() async {
    final value = _box.get(_newsKey, defaultValue: <dynamic>[]) as List<dynamic>;
    return value
        .whereType<Map>()
        .map((item) => News.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class HiveLeaderboardCacheStorage {
  static const String _boxName = 'leaderboardCacheStorage';
  static const String _competitionsKey = 'competitions';
  static const String _examsKey = 'leaderboard_exams';
  static late Box<dynamic> _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<dynamic>(_boxName);
    } else {
      _box = Hive.box<dynamic>(_boxName);
    }
  }

  Future<void> setCompetitions(List<Map<String, dynamic>> competitions) async {
    await _box.put(_competitionsKey, competitions);
  }

  Future<List<Map<String, dynamic>>> getCompetitions() async {
    final value = _box.get(
      _competitionsKey,
      defaultValue: <dynamic>[],
    ) as List<dynamic>;
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> setExams(List<Exam> exams) async {
    final jsonList = exams.map((item) => item.toJson()).toList();
    await _box.put(_examsKey, jsonList);
  }

  Future<List<Exam>> getExams() async {
    final value = _box.get(_examsKey, defaultValue: <dynamic>[]) as List<dynamic>;
    return value
        .whereType<Map>()
        .map((item) => Exam.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> setLeaderboardEntries({
    required String type,
    required int sourceId,
    required List<LeaderboardEntry> entries,
  }) async {
    final key = '${type}_$sourceId';
    final jsonList = entries.map((item) => item.toJson()).toList();
    await _box.put(key, jsonList);
  }

  Future<List<LeaderboardEntry>> getLeaderboardEntries({
    required String type,
    required int sourceId,
  }) async {
    final key = '${type}_$sourceId';
    final value = _box.get(key, defaultValue: <dynamic>[]) as List<dynamic>;
    return value
        .whereType<Map>()
        .map((item) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
