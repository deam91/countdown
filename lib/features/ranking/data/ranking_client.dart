import 'package:countdown/features/ranking/domain/rank_item.dart';

/// Abstraction over "produce a stream of ranked items for a query."
///
/// Two implementations:
/// - `CountdownOpenAIClient` — real OpenAI call.
/// - `SeedRankingClient` — hardcoded fixture for development / demos
///   without an API key. Gate via `--dart-define=SEED_MODE=true`.
abstract interface class RankingClient {
  Stream<RankItem> rank({required String query, int n = 10});
  void dispose();
}
