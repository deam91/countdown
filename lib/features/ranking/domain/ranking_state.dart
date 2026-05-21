import 'package:countdown/core/errors.dart';
import 'package:countdown/features/ranking/domain/rank_item.dart';
import 'package:countdown/features/ranking/domain/ranking.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking_state.freezed.dart';

/// State machine for a ranking request.
///   idle → loading → streaming(partial) → done(full)
///                 ↘ error
@freezed
sealed class RankingState with _$RankingState {
  const factory RankingState.idle() = RankingIdle;
  const factory RankingState.loading({required String query}) = RankingLoading;
  const factory RankingState.streaming({
    required String query,
    required List<RankItem> partial,
  }) = RankingStreaming;
  const factory RankingState.done(Ranking ranking) = RankingDone;
  const factory RankingState.error(AppError error) = RankingError;
}
