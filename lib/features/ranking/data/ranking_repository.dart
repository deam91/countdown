import 'dart:async';

import 'package:countdown/core/errors.dart';
import 'package:countdown/features/ranking/data/openai_client.dart';
import 'package:countdown/features/ranking/data/ranking_cache.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:countdown/features/ranking/domain/ranking.dart';
import 'package:countdown/features/ranking/domain/ranking_state.dart';

/// Coordinates the cache and the OpenAI client. Cache-first; on miss,
/// streams from OpenAI and persists the result on completion.
class RankingRepository {
  RankingRepository({
    required this._client,
    required this._cache,
  });

  final CountdownOpenAIClient _client;
  final RankingCache _cache;

  /// Drives the state machine for a ranking request.
  ///
  ///   loading → streaming(partial) → done(full)
  ///                              ↘ error
  Stream<RankingState> ranking({
    required String query,
    int n = 10,
  }) async* {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      yield const RankingState.error(UnknownError('Query is empty.'));
      return;
    }

    yield RankingState.loading(query: trimmed);

    final cached = _cache.get(trimmed);
    if (cached != null) {
      yield* _drip(query: trimmed, items: cached.items, fromCache: true);
      return;
    }

    final collected = <RankItem>[];
    try {
      await for (final item in _client.rank(query: trimmed, n: n)) {
        collected.add(item);
        yield RankingState.streaming(query: trimmed, partial: List.unmodifiable(collected));
      }
    } on AppError catch (e) {
      yield RankingState.error(e);
      return;
    }

    final ranking = Ranking(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      query: trimmed,
      items: collected,
      createdAt: DateTime.now(),
    );
    unawaited(_cache.put(ranking));
    yield RankingState.done(ranking);
  }

  /// Re-emits a cached ranking with the same cadence as a live stream so
  /// the reveal animation still feels alive on a cache hit.
  Stream<RankingState> _drip({
    required String query,
    required List<RankItem> items,
    required bool fromCache,
  }) async* {
    final partial = <RankItem>[];
    for (final item in items) {
      partial.add(item);
      yield RankingState.streaming(query: query, partial: List.unmodifiable(partial));
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    yield RankingState.done(
      Ranking(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        query: query,
        items: items,
        createdAt: DateTime.now(),
      ),
    );
  }
}
