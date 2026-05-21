import 'dart:async';

import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';

/// Pulls a thumbnail (and, for places, real coordinates) from Wikipedia
/// for each ranked item. Free, no auth, CORS-friendly.
///
/// Two-step REST per item:
///   1. `/w/rest.php/v1/search/page?q={title}&limit=1` resolves the
///      actual Wikipedia page title (handles disambiguation, e.g.
///      "Hereditary" → "Hereditary (film)").
///   2. `/api/rest_v1/page/summary/{title}` returns `thumbnail.source`
///      and, for pages with infobox coordinates, `coordinates.{lat,lon}`.
///
/// Items with no Wikipedia match come back unchanged. Place items keep
/// the model's `lat`/`lng` when Wikipedia doesn't have coordinates.
class WikipediaImageLookup {
  WikipediaImageLookup(this._dio) {
    // Wikipedia's REST API aggressively rate-limits unidentified clients
    // (10-20 req/sec hits 429 instantly). Their policy requires a
    // descriptive User-Agent identifying the app.
    // https://meta.wikimedia.org/wiki/User-Agent_policy
    _dio.options.headers['User-Agent'] = 'CountdownApp/1.0 (Flutter; Dart/Dio)';

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
  /// Parallel was attempted and tripped Wikipedia's 429 limiter; retries
  /// stacked and re-hit the limit at every backoff moment.
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
      final summary = await _lookup(title).timeout(_perLookupTimeout);
      if (summary == null || summary.isEmpty) {
        debugPrint('[wiki] miss: $title');
        return item;
      }
      debugPrint(
        '[wiki] hit:  $title → ${summary.imageUrl ?? "(no thumb)"} '
        '${summary.lat != null ? "[${summary.lat}, ${summary.lon}]" : ""}',
      );
      return _apply(item, summary);
    } on Object catch (e) {
      debugPrint('[wiki] err:  $title → $e');
      return item;
    }
  }

  Future<_WikiSummary?> _lookup(String title) async {
    final resolvedTitle = await _resolveTitle(title);
    if (resolvedTitle == null) return null;
    return _fetchSummary(resolvedTitle);
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

  Future<_WikiSummary> _fetchSummary(String title) async {
    final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));
    final response = await _dio.get<Map<String, dynamic>>(
      '$_summaryEndpoint$encoded',
    );
    final data = response.data;

    String? imageUrl;
    final thumb = data?['thumbnail'];
    if (thumb is Map<String, dynamic>) {
      final source = thumb['source'];
      if (source is String && source.isNotEmpty) imageUrl = source;
    }

    double? lat;
    double? lon;
    final coords = data?['coordinates'];
    if (coords is Map<String, dynamic>) {
      final rawLat = coords['lat'];
      final rawLon = coords['lon'];
      if (rawLat is num) lat = rawLat.toDouble();
      if (rawLon is num) lon = rawLon.toDouble();
    }

    return _WikiSummary(imageUrl: imageUrl, lat: lat, lon: lon);
  }

  RankItem _apply(RankItem item, _WikiSummary s) {
    switch (item) {
      case final PlaceItem i:
        return i.copyWith(
          imageUrl: s.imageUrl ?? i.imageUrl,
          lat: s.lat ?? i.lat,
          lng: s.lon ?? i.lng,
        );
      case final BookItem i:
        return s.imageUrl == null ? i : i.copyWith(imageUrl: s.imageUrl);
      case final PersonItem i:
        return s.imageUrl == null ? i : i.copyWith(imageUrl: s.imageUrl);
      case final GenericItem i:
        return s.imageUrl == null ? i : i.copyWith(imageUrl: s.imageUrl);
    }
  }

  String _titleOf(RankItem item) => switch (item) {
        PlaceItem(:final title) => title,
        BookItem(:final title) => title,
        PersonItem(:final title) => title,
        GenericItem(:final title) => title,
      };
}

class _WikiSummary {
  const _WikiSummary({this.imageUrl, this.lat, this.lon});
  final String? imageUrl;
  final double? lat;
  final double? lon;

  bool get isEmpty => imageUrl == null && lat == null && lon == null;
}
