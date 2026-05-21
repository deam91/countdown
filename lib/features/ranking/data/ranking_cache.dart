import 'dart:async';
import 'dart:convert';

import 'package:countdown/features/ranking/data/prompt_builder.dart';
import 'package:countdown/features/ranking/domain/ranking.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Invisible query → ranking cache backed by hive_ce. No UI — see
/// `IDEA.md §3.6 "Caching (invisible to the user)"`.
///
/// LRU-50 by insertion order. Stored as JSON strings keyed by a
/// normalized query (lowercased, whitespace-collapsed).
class RankingCache {
  RankingCache._(this._box);

  /// Opens (or creates) the hive box. Call once during app init.
  static Future<RankingCache> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(_boxName);
    return RankingCache._(box);
  }

  // v5 = items now carry a long-form `details` string distinct from
  // `whyItRanks`; old entries would fail deserialization.
  static const String _boxName = 'ranking_cache_v5';
  static const int _maxEntries = 50;

  final Box<String> _box;

  /// Returns the cached ranking for [query] if present, else null.
  Ranking? get(String query) {
    final key = PromptBuilder.normalize(query);
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return Ranking.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      // Corrupt entry — drop it.
      unawaited(_box.delete(key));
      return null;
    }
  }

  /// Persists [ranking] under its normalized query. Evicts the oldest
  /// entry if over the LRU cap.
  Future<void> put(Ranking ranking) async {
    final key = PromptBuilder.normalize(ranking.query);
    await _box.put(key, jsonEncode(ranking.toJson()));
    await _trim();
  }

  Future<void> _trim() async {
    if (_box.length <= _maxEntries) return;
    // Hive preserves insertion order via box.keys. Evict oldest first.
    final excess = _box.length - _maxEntries;
    final toDelete = _box.keys.take(excess).toList(growable: false);
    await _box.deleteAll(toDelete);
  }

  /// For tests + future history features. Returns most recent first.
  Iterable<String> recentKeys({int limit = 10}) =>
      _box.keys.cast<String>().toList().reversed.take(limit);

  Future<void> clear() => _box.clear();
}
