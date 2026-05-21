import 'dart:async';

import 'package:countdown/core/errors.dart';
import 'package:countdown/features/ranking/data/ranking_cache.dart';
import 'package:countdown/features/ranking/data/ranking_client.dart';
import 'package:countdown/features/ranking/data/wikipedia_image_lookup.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:countdown/features/ranking/domain/ranking.dart';
import 'package:countdown/features/ranking/domain/ranking_state.dart';

/// Coordinates the cache, the OpenAI client, and the Wikipedia image
/// enricher. Cache-first; on miss: OpenAI → Wikipedia enrichment →
/// persisted to cache → dripped out to UI at 220ms cadence.
class RankingRepository {
  RankingRepository({
    required this._client,
    required this._cache,
    required this._imageLookup,
  });

  final RankingClient _client;
  final RankingCache _cache;
  final WikipediaImageLookup _imageLookup;

  /// Drip cadence between revealed cards. The UI's reveal animation
  /// runs in parallel, so this is the perceived pace of the countdown.
  static const Duration _dripDelay = Duration(milliseconds: 220);

  /// Drives the state machine for a ranking request.
  ///
  ///   loading → streaming(partial) → done(full)
  ///                              ↘ error
  ///
  /// On a cache miss: OpenAI returns raw items → Wikipedia is queried
  /// in parallel for thumbnails → enriched items are persisted to cache
  /// → dripped out at [_dripDelay] cadence.
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
      yield* _drip(query: trimmed, items: cached.items);
      return;
    }

    // Phase 1 — collect all items from OpenAI.
    final List<RankItem> rawItems;
    try {
      rawItems = await _client.rank(query: trimmed, n: n).toList();
    } on AppError catch (e) {
      yield RankingState.error(e);
      return;
    }

    // Phase 2 — enrich images via Wikipedia in parallel.
    final enriched = await _imageLookup.enrichAll(rawItems);

    // Persist before dripping so the cache is warm even if the user
    // navigates away mid-reveal.
    final ranking = Ranking(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      query: trimmed,
      items: enriched,
      createdAt: DateTime.now(),
    );
    unawaited(_cache.put(ranking));

    // Phase 3 — drip the enriched items.
    yield* _drip(query: trimmed, items: enriched);
  }

  /// Drips items at [_dripDelay] cadence, ending with `RankingState.done`.
  Stream<RankingState> _drip({
    required String query,
    required List<RankItem> items,
  }) async* {
    final partial = <RankItem>[];
    for (final item in items) {
      partial.add(item);
      yield RankingState.streaming(
        query: query,
        partial: List.unmodifiable(partial),
      );
      await Future<void>.delayed(_dripDelay);
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
