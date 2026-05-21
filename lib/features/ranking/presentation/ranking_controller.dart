import 'dart:async';

import 'package:countdown/core/env.dart';
import 'package:countdown/core/errors.dart';
import 'package:countdown/features/ranking/data/openai_client.dart';
import 'package:countdown/features/ranking/data/ranking_cache.dart';
import 'package:countdown/features/ranking/data/ranking_client.dart';
import 'package:countdown/features/ranking/data/ranking_repository.dart';
import 'package:countdown/features/ranking/data/seed_ranking_client.dart';
import 'package:countdown/features/ranking/domain/ranking_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================================
/// Providers (manual — see CLAUDE.md "State" section for why we dropped codegen)
/// ============================================================================

/// Singleton ranking client. [SeedRankingClient] in dev fixture mode,
/// real [CountdownOpenAIClient] otherwise. Disposed on tear-down.
final rankingClientProvider = Provider<RankingClient>((ref) {
  if (Env.seedMode) {
    final client = SeedRankingClient();
    ref.onDispose(client.dispose);
    return client;
  }
  if (!Env.hasOpenAiKey) {
    throw const AuthError(
      'OPENAI_API_KEY missing — set via --dart-define at run time.',
    );
  }
  final client = CountdownOpenAIClient(apiKey: Env.openAiApiKey);
  ref.onDispose(client.dispose);
  return client;
});

/// Cache — opened lazily, awaited by `rankingControllerProvider` on first use.
final rankingCacheProvider = FutureProvider<RankingCache>((ref) {
  return RankingCache.open();
});

/// Repository — composes the client and cache.
final rankingRepositoryProvider = FutureProvider<RankingRepository>((ref) async {
  final cache = await ref.watch(rankingCacheProvider.future);
  final client = ref.watch(rankingClientProvider);
  return RankingRepository(client: client, cache: cache);
});

/// ============================================================================
/// Ranking controller — drives the screen's state machine
/// ============================================================================

class RankingController extends Notifier<RankingState> {
  StreamSubscription<RankingState>? _sub;

  @override
  RankingState build() {
    ref.onDispose(() {
      unawaited(_sub?.cancel());
    });
    return const RankingState.idle();
  }

  /// Kicks off a new ranking request. Cancels any in-flight stream.
  Future<void> ask(String query, {int n = 10}) async {
    await _sub?.cancel();
    state = RankingState.loading(query: query.trim());

    try {
      final repo = await ref.read(rankingRepositoryProvider.future);
      _sub = repo.ranking(query: query, n: n).listen(
        (next) {
          state = next;
        },
        onError: (Object e, StackTrace _) {
          state = RankingState.error(
            e is AppError ? e : UnknownError(e.toString()),
          );
        },
      );
    } on AppError catch (e) {
      state = RankingState.error(e);
    } on Object catch (e) {
      state = RankingState.error(UnknownError(e.toString()));
    }
  }

  /// Returns to idle. Useful when navigating back to Search.
  void reset() {
    unawaited(_sub?.cancel());
    _sub = null;
    state = const RankingState.idle();
  }
}

final rankingControllerProvider =
    NotifierProvider<RankingController, RankingState>(RankingController.new);
