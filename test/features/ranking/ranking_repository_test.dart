import 'package:countdown/core/errors.dart';
import 'package:countdown/features/ranking/data/openai_client.dart';
import 'package:countdown/features/ranking/data/ranking_cache.dart';
import 'package:countdown/features/ranking/data/ranking_repository.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:countdown/features/ranking/domain/ranking.dart';
import 'package:countdown/features/ranking/domain/ranking_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeClient extends Mock implements CountdownOpenAIClient {}

class _FakeCache extends Mock implements RankingCache {}

void main() {
  late _FakeClient client;
  late _FakeCache cache;
  late RankingRepository repo;

  final items = [
    const RankItem.generic(
      rank: 2,
      title: 'Second',
      whyItRanks: 'Solid runner-up',
      score: 8,
    ),
    const RankItem.generic(
      rank: 1,
      title: 'First',
      whyItRanks: 'Clear winner',
      score: 9.5,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(
      Ranking(id: '_', query: '_', items: const [], createdAt: DateTime(2026)),
    );
  });

  setUp(() {
    client = _FakeClient();
    cache = _FakeCache();
    repo = RankingRepository(client: client, cache: cache);
    when(() => cache.put(any())).thenAnswer((_) async {});
  });

  test('on cache miss → loading, streaming×N, done', () async {
    when(() => cache.get(any())).thenReturn(null);
    when(() => client.rank(query: any(named: 'query'), n: any(named: 'n')))
        .thenAnswer((_) => Stream.fromIterable(items));

    final states = await repo.ranking(query: 'top 2 things').toList();

    expect(states.first, isA<RankingLoading>());
    expect(states.whereType<RankingStreaming>().length, items.length);
    expect(states.last, isA<RankingDone>());
    final done = states.last as RankingDone;
    expect(done.ranking.items.length, 2);
    verify(() => cache.put(any())).called(1);
  });

  test('on cache hit → uses cached items, does not call client', () async {
    final cached = Ranking(
      id: 'x',
      query: 'top 2 things',
      items: items,
      createdAt: DateTime.now(),
    );
    when(() => cache.get(any())).thenReturn(cached);

    final states = await repo.ranking(query: 'top 2 things').toList();

    expect(states.first, isA<RankingLoading>());
    expect(states.last, isA<RankingDone>());
    verifyNever(
      () => client.rank(query: any(named: 'query'), n: any(named: 'n')),
    );
  });

  test('client error → state.error', () async {
    when(() => cache.get(any())).thenReturn(null);
    when(() => client.rank(query: any(named: 'query'), n: any(named: 'n')))
        .thenAnswer((_) => Stream.error(const RateLimitError()));

    final states = await repo.ranking(query: 'top 2 things').toList();

    expect(states.last, isA<RankingError>());
    expect((states.last as RankingError).error, isA<RateLimitError>());
  });

  test('empty query → state.error without touching cache or client', () async {
    final states = await repo.ranking(query: '   ').toList();

    expect(states, hasLength(1));
    expect(states.first, isA<RankingError>());
    verifyNever(() => cache.get(any()));
    verifyNever(
      () => client.rank(query: any(named: 'query'), n: any(named: 'n')),
    );
  });
}
