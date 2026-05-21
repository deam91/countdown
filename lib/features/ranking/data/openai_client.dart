import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:countdown/core/errors.dart';
import 'package:countdown/features/ranking/data/prompt_builder.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:openai_dart/openai_dart.dart';

/// Thin wrapper over `openai_dart` that streams typed [RankItem]s for a
/// ranking query.
///
/// The model returns the full JSON in one structured response (json_schema),
/// but we drip items out one-by-one with a small delay so the countdown
/// reveal animation has time to play. A future upgrade is to tolerantly
/// parse the streaming JSON for true item-by-item streaming — see IDEA.md §7.
class CountdownOpenAIClient {
  CountdownOpenAIClient({
    required String apiKey,
    this._model = 'gpt-4o-mini',
  })  : _client = OpenAIClient.withApiKey(apiKey);

  final OpenAIClient _client;
  final String _model;

  /// Tiny delay between drips so cards animate in with a visible cadence.
  static const Duration _dripDelay = Duration(milliseconds: 220);

  /// Streams ranked items as they become available. Items arrive in
  /// **countdown order** — rank N first, rank 1 last.
  ///
  /// Throws an [AppError] on any failure. Cancelling the subscription
  /// stops the drip but does not abort the in-flight HTTP request
  /// (the request is short — typically <3s).
  Stream<RankItem> rank({
    required String query,
    int n = 10,
  }) async* {
    final fullText = await _completeAsText(query: query, n: n);
    final items = _parseItems(fullText);

    for (final item in items) {
      yield item;
      await Future<void>.delayed(_dripDelay);
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
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(RankItem.fromJson)
        .toList(growable: false);
  }

  void dispose() => _client.close();
}
