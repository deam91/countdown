import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:countdown/core/errors.dart';
import 'package:countdown/features/ranking/data/prompt_builder.dart';
import 'package:countdown/features/ranking/data/ranking_client.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart';

/// Thin wrapper over `openai_dart` that yields typed [RankItem]s for a
/// ranking query.
///
/// The model returns the full JSON in one structured response (json_schema);
/// we parse it and emit items as a stream. The drip cadence between
/// items is owned by `RankingRepository`, not this client — the client
/// returns items as fast as it can. Image enrichment happens after this
/// stream completes (see `WikipediaImageLookup`).
class CountdownOpenAIClient implements RankingClient {
  /// `gpt-4o-mini` for ranking generation only — no web search, no
  /// image URL responsibility. Cheap (~$0.001/query), fast (~3s).
  /// Image URLs are added downstream by WikipediaImageLookup.
  CountdownOpenAIClient({
    required String apiKey,
    this._model = 'gpt-4o-mini',
  })  : _client = OpenAIClient.withApiKey(apiKey);

  final OpenAIClient _client;
  final String _model;

  /// Yields ranked items in **countdown order** (rank N first, rank 1
  /// last) as fast as they're parsed. The repository owns the drip
  /// cadence so it can sit between this stream and the UI.
  @override
  Stream<RankItem> rank({
    required String query,
    int n = 10,
  }) async* {
    final fullText = await _completeAsText(query: query, n: n);
    for (final item in _parseItems(fullText)) {
      yield item;
    }
  }

  Future<String> _completeAsText({
    required String query,
    required int n,
  }) async {
    final stream = _client.chat.completions.createStream(
      ChatCompletionCreateRequest(
        model: _model,
        messages: [
          ChatMessage.system(PromptBuilder.systemPrompt(n)),
          ChatMessage.user(query),
        ],
        responseFormat: ResponseFormat.jsonSchema(
          name: 'ranking',
          schema: PromptBuilder.schema(n),
        ),
      ),
    );

    final buffer = StringBuffer();
    try {
      await for (final event in stream) {
        if (event.textDelta case final delta?) buffer.write(delta);
      }
    } on AuthenticationException catch (e) {
      throw AuthError(e.message);
    } on RateLimitException catch (e) {
      throw RateLimitError(retryAfter: e.retryAfter, message: e.message);
    } on RequestTimeoutException catch (_) {
      throw const TimeoutError();
    } on ConnectionException catch (_) {
      throw const NetworkError();
    } on ApiException catch (e) {
      if (e.statusCode >= 500) throw NetworkError(e.message);
      throw UnknownError(e.message);
    } on ParseException catch (_) {
      throw const MalformedResponseError();
    } on StreamException catch (e) {
      throw NetworkError(e.message);
    } on SocketException catch (_) {
      throw const NetworkError();
    } on TimeoutException catch (_) {
      throw const TimeoutError();
    }
    return buffer.toString();
  }

  List<RankItem> _parseItems(String fullText) {
    final Object? decoded;
    try {
      decoded = jsonDecode(fullText);
    } on FormatException {
      throw const MalformedResponseError();
    }
    if (decoded is! Map<String, dynamic>) {
      throw const MalformedResponseError('Top-level JSON is not an object.');
    }
    final rawItems = decoded['items'];
    if (rawItems is! List) {
      throw const MalformedResponseError('Missing "items" array.');
    }
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(RankItem.fromJson)
        .toList(growable: false);
    _logImageUrls(items);
    return items;
  }

  /// Debug-only inventory of imageUrls returned by GPT. Helps diagnose
  /// when the web search is working vs. when the model is null-ing every
  /// URL. No-op in release.
  void _logImageUrls(List<RankItem> items) {
    debugPrint('[openai] ${items.length} items received. imageUrls:');
    for (final item in items) {
      final (rank, kind, url) = switch (item) {
        PlaceItem(:final rank, :final imageUrl) => (rank, 'place', imageUrl),
        BookItem(:final rank, :final imageUrl) => (rank, 'book', imageUrl),
        PersonItem(:final rank, :final imageUrl) => (rank, 'person', imageUrl),
        GenericItem(:final rank, :final imageUrl) => (rank, 'generic', imageUrl),
      };
      debugPrint(
        '[openai]   #${rank.toString().padLeft(2)} ${kind.padRight(8)} → ${url ?? '(null)'}',
      );
    }
  }

  @override
  void dispose() => _client.close();
}
