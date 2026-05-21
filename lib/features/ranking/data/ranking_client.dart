import 'package:countdown/features/ranking/domain/rank_item.dart';

/// Abstraction over "produce a stream of ranked items for a query."
/// Implemented by `CountdownOpenAIClient`. The interface exists so the
/// repository can be unit-tested without hitting the network.
abstract interface class RankingClient {
  Stream<RankItem> rank({required String query, int n = 10});
  void dispose();
}
