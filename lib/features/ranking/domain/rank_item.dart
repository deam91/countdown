import 'package:freezed_annotation/freezed_annotation.dart';

part 'rank_item.freezed.dart';
part 'rank_item.g.dart';

/// A single item in a ranking. Sealed by `kind` so the UI dispatches
/// the right card variant.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
sealed class RankItem with _$RankItem {
  const factory RankItem.place({
    required int rank,
    required String title,
    required String whyItRanks,
    required double score,
    required String address,
    required double lat,
    required double lng,
    String? imageUrl,
  }) = PlaceItem;

  const factory RankItem.book({
    required int rank,
    required String title,
    required String whyItRanks,
    required double score,
    required String author,
    int? year,
    String? imageUrl,
  }) = BookItem;

  const factory RankItem.person({
    required int rank,
    required String title,
    required String whyItRanks,
    required double score,
    required String tagline,
    String? imageUrl,
  }) = PersonItem;

  const factory RankItem.generic({
    required int rank,
    required String title,
    required String whyItRanks,
    required double score,
    String? imageUrl,
  }) = GenericItem;

  factory RankItem.fromJson(Map<String, dynamic> json) =>
      _$RankItemFromJson(json);
}
