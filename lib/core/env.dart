/// Environment / secret access.
///
/// Pass the OpenAI API key at compile time via:
///   flutter run --dart-define=OPENAI_API_KEY=sk-...
///
/// The key NEVER touches the repo. See README for full setup.
abstract final class Env {
  // FIND-ME: OPENAI_API_KEY
  // Set this constant via --dart-define at build/run time.
  // Required by the Labhouse brief: "define a constant and write a comment to find it faster".
  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  // Unsplash access key (optional — image enrichment degrades gracefully if absent).
  static const String unsplashAccessKey =
      String.fromEnvironment('UNSPLASH_ACCESS_KEY');

  /// Dev fixture mode — set via `--dart-define=SEED_MODE=true` to bypass
  /// OpenAI and stream a curated fixture. Useful for demos / visual review
  /// without burning API quota.
  static const bool seedMode =
      bool.fromEnvironment('SEED_MODE');

  static bool get hasOpenAiKey => openAiApiKey.isNotEmpty;
  static bool get hasUnsplashKey => unsplashAccessKey.isNotEmpty;
}
