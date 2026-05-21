import 'dart:async';

import 'package:countdown/features/ranking/data/ranking_client.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';

/// Development / demo fixture. Returns 10 hardcoded items in countdown
/// order (rank 10 → 1) with a 220ms drip cadence so the full reveal
/// can be verified without an OpenAI API call. Mix covers all four
/// [RankItem] kinds.
///
/// Activated via `--dart-define=SEED_MODE=true`. Must NEVER be wired
/// into a release build target.
class SeedRankingClient implements RankingClient {
  static const Duration _dripDelay = Duration(milliseconds: 220);

  @override
  Stream<RankItem> rank({required String query, int n = 10}) async* {
    // Initial "thinking" delay so the loading state is briefly visible.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    for (final item in _items.take(n)) {
      yield item;
      await Future<void>.delayed(_dripDelay);
    }
  }

  @override
  void dispose() {}

  // Curated mix: 4 places, 2 books, 2 people, 2 generic.
  // Ordered worst → best so #10 streams first, #1 last.
  static const List<RankItem> _items = [
    RankItem.generic(
      rank: 10,
      title: 'Tonkotsu Cup Noodle',
      whyItRanks: 'Convenience-store nostalgia in a styrofoam cup',
      score: 5.4,
    ),
    RankItem.place(
      rank: 9,
      title: 'Ramen Jirou Mita Honten',
      whyItRanks: 'Mountain-of-noodles cult favorite — bring an appetite',
      score: 6.8,
      address: 'Minato, Tokyo',
      lat: 35.6494,
      lng: 139.7396,
    ),
    RankItem.person(
      rank: 8,
      title: 'Ivan Orkin',
      whyItRanks: 'Brooklynite who out-ramened Tokyo',
      score: 7.2,
      tagline: 'Founder, Ivan Ramen',
    ),
    RankItem.generic(
      rank: 7,
      title: 'Late-night yatai stalls',
      whyItRanks: 'Steam + paper lanterns + tonkotsu broth at 2am',
      score: 7.6,
    ),
    RankItem.book(
      rank: 6,
      title: 'Ivan Ramen',
      whyItRanks: 'The memoir-cookbook hybrid that demystified the broth',
      score: 7.9,
      author: 'Ivan Orkin',
      year: 2013,
    ),
    RankItem.place(
      rank: 5,
      title: 'Afuri',
      whyItRanks: 'Yuzu-shio: bright citrus over clean chicken broth',
      score: 8.2,
      address: 'Ebisu, Tokyo',
      lat: 35.6464,
      lng: 139.7100,
    ),
    RankItem.person(
      rank: 4,
      title: 'Kazuo Yamagishi',
      whyItRanks: 'Father of tsukemen — invented the dipping format in 1955',
      score: 8.6,
      tagline: 'Founder, Taishoken',
    ),
    RankItem.place(
      rank: 3,
      title: 'Tsuta',
      whyItRanks: 'First ramen shop to earn a Michelin star — truffle shoyu',
      score: 9.1,
      address: 'Sugamo, Tokyo',
      lat: 35.7335,
      lng: 139.7393,
    ),
    RankItem.book(
      rank: 2,
      title: 'The Ramen King and I',
      whyItRanks: 'Andy Raskin chases Momofuku Ando through love and noodles',
      score: 9.3,
      author: 'Andy Raskin',
      year: 2009,
    ),
    RankItem.place(
      rank: 1,
      title: 'Ichiran Shibuya',
      whyItRanks: 'Solo-booth tonkotsu, customizable everything, 24 hours',
      score: 9.6,
      address: 'Shibuya, Tokyo',
      lat: 35.6595,
      lng: 139.7005,
    ),
  ];
}
