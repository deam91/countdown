import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking.freezed.dart';
part 'ranking.g.dart';

/// A completed (or in-progress) ranking response.
@freezed
abstract class Ranking with _$Ranking {
  const factory Ranking({
    required String id,
    required String query,
    required List<RankItem> items,
    required DateTime createdAt,
  }) = _Ranking;

  factory Ranking.fromJson(Map<String, dynamic> json) =>
      _$RankingFromJson(json);
}
