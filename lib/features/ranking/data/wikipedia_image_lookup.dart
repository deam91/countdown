import 'dart:async';

import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';

/// Looks up a thumbnail image for each item from Wikipedia.
///
/// Uses MediaWiki's combined search + pageimages endpoint so a single
/// HTTP call per item resolves the best-matching Wikipedia page AND
/// returns its 300px thumbnail. Free, no auth, CORS-friendly.
///
/// Items whose title has no Wikipedia match (or no thumbnail) come back
/// unchanged — the kind-specific placeholder icon in `RankCard` then
/// reads as a deliberate "no image" rather than a broken URL.
class WikipediaImageLookup {
  WikipediaImageLookup(this._dio) {
    // Wikipedia's REST API aggressively rate-limits unidentified clients
    // (10-20 req/sec hits 429 instantly). Their policy requires a
    // descriptive User-Agent identifying the app.
    // https://meta.wikimedia.org/wiki/User-Agent_policy
    _dio.options.headers['User-Agent'] = 'CountdownApp/1.0 (Flutter; Dart/Dio)';

    // Even with a polite User-Agent, a burst of 20 parallel HTTPS hits
    // can trip the rate limiter. Auto-retry 429s with backoff so the
    // hit rate isn't sacrificed for speed.
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 2,
        retryDelays: const [
          Duration(milliseconds: 500),
          Duration(milliseconds: 1500),
        ],
        retryableExtraStatuses: const {429},
      ),
    );
  }

  final Dio _dio;

  static const String _searchEndpoint =
      'https://en.wikipedia.org/w/rest.php/v1/search/page';
  static const String _summaryEndpoint =
      'https://en.wikipedia.org/api/rest_v1/page/summary/';
  static const Duration _perLookupTimeout = Duration(seconds: 3);

  /// Enriches all items sequentially. ~300ms per item × 10 = ~3s total.
  ///
  /// Why not parallel: Wikipedia's REST API rate-limits per-IP at the
  /// MediaWiki edge. Even batches of 2 with retry-on-429 still tripped
  /// the limiter because retries stack — multiple in-flight requests
  /// that 429'd all retry at the same backoff moment, hammering the
  /// limit again. One-at-a-time eliminates the burst entirely and stays
  /// well under the threshold.
  Future<List<RankItem>> enrichAll(List<RankItem> items) async {
    final out = <RankItem>[];
    for (final item in items) {
      out.add(await _enrichOne(item));
    }
    return out;
  }

  Future<RankItem> _enrichOne(RankItem item) async {
    final title = _titleOf(item);
    try {
      final url = await _lookup(title).timeout(_perLookupTimeout);
      if (url == null) {
        debugPrint('[wiki] miss: $title');
        return item;
      }
      debugPrint('[wiki] hit:  $title → $url');
      return _withImageUrl(item, url);
    } on Object catch (e) {
      debugPrint('[wiki] err:  $title → $e');
      return item;
    }
  }

  /// Two-step lookup:
  ///   1. REST search to resolve the actual Wikipedia page title
  ///      (handles disambiguation, e.g. "Hereditary" → "Hereditary (film)").
  ///   2. REST summary on that title to get the thumbnail URL.
  ///
  /// Both endpoints are unauthenticated and CORS-friendly.
  Future<String?> _lookup(String title) async {
    final resolvedTitle = await _resolveTitle(title);
    if (resolvedTitle == null) return null;
    return _summaryThumbnail(resolvedTitle);
  }

  Future<String?> _resolveTitle(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _searchEndpoint,
      queryParameters: <String, String>{'q': query, 'limit': '1'},
    );
    final pages = response.data?['pages'];
    if (pages is! List || pages.isEmpty) return null;
    final first = pages.first;
    if (first is! Map<String, dynamic>) return null;
    final t = first['title'];
    return t is String && t.isNotEmpty ? t : null;
  }

  Future<String?> _summaryThumbnail(String title) async {
    final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));
    final response = await _dio.get<Map<String, dynamic>>(
      '$_summaryEndpoint$encoded',
    );
    final thumb = response.data?['thumbnail'];
    if (thumb is! Map<String, dynamic>) return null;
    final source = thumb['source'];
    return source is String && source.isNotEmpty ? source : null;
  }

  String _titleOf(RankItem item) => switch (item) {
        PlaceItem(:final title) => title,
        BookItem(:final title) => title,
        PersonItem(:final title) => title,
        GenericItem(:final title) => title,
      };

  RankItem _withImageUrl(RankItem item, String url) => switch (item) {
        final PlaceItem i => i.copyWith(imageUrl: url),
        final BookItem i => i.copyWith(imageUrl: url),
        final PersonItem i => i.copyWith(imageUrl: url),
        final GenericItem i => i.copyWith(imageUrl: url),
      };
}
