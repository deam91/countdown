# CLAUDE.md — Countdown (Flutter)

A Flutter iOS app that turns "give me the top N…" questions into a cinematic streaming countdown reveal using the OpenAI API. Built for the Labhouse Option B technical test.

**Full spec:** see [`IDEA.md`](./IDEA.md) — that file is the source of truth for design, architecture, scope, and rationale. Keep it in sync when meaningful changes happen.

**Visual source of truth:** [`design/`](./design/) — `countdown.html` is the live artboard (open in a browser); `design/screenshots/` holds PNG mockups (01–07) referenced inline in `IDEA.md` §3. When porting a screen to Flutter, **the screenshot is the contract** — pixel parity over interpretation.

**Build status:** see [`IDEA.md` §14b](./IDEA.md#14b-build-status-live) — the live checklist of what's scaffolded vs. still TODO. Update it as you ship.

---

## At a glance

- **Platform:** iOS (Android skipped per brief). Bundle: `com.diaz.countdown`.
- **Flutter:** pinned to **3.44.0** via FVM (`.fvmrc`). Always invoke as `fvm flutter ...` (or via the `Makefile`).
- **State:** `flutter_riverpod` **^3.3.1** with **manual providers**. The codegen ecosystem (`riverpod_annotation` / `_generator` / `_lint` / `custom_lint`) was dropped — its analyzer pin (7-9) conflicts with `json_serializable ^6.14` (analyzer 10+). Costs ~5 lines per provider; keeps everything else current.
- **Models:** `freezed` ^3.2.5 + `json_serializable` ^6.14.0 (run `make gen` after model edits).
- **AI:** **`openai_dart` ^5.0.0** — streaming chat completions against **`gpt-4o-mini`** with `response_format: json_schema`. Ranking text only — image URLs come from Wikipedia (see below). ~$0.001/query, ~3s. Both `gpt-4o-mini-search-preview` and `gpt-4o-search-preview` were tried for image URLs and both hallucinated paths even with web search; the only reliable path is enriching post-hoc. **Don't write a custom SSE parser** — the package handles it.
- **Image enrichment:** **`WikipediaImageLookup`** — two-step REST per item (search → summary), processed **sequentially** (~300ms each, ~3s for 10 items). Lives between OpenAI and the drip in `RankingRepository`. Free, no auth. Parallel was attempted and reliably hit Wikipedia's 429 limiter — retries stacked and re-hit the limit at every backoff moment. Sequential gives way higher hit rate for ~2s more latency.
- **HTTP (non-AI):** `dio` ^5.9.2 + `dio_smart_retry` ^7.0.1 + `pretty_dio_logger` ^1.4.0 (used for Unsplash; AI traffic goes through `openai_dart`).
- **Maps:** `flutter_map` + OpenStreetMap (no Google Maps key).
- **Fonts:** `google_fonts` — Fraunces (display) + Inter (UI).
- **Icons:** **`lucide_icons_flutter`** (the active fork — never use `lucide_icons`, last shipped 2023).
- **Local storage:** **`hive_ce`** + `path_provider` (community edition; original `hive` unmaintained since 2022). Used purely as an invisible query → ranking cache (LRU, max 50, no TTL). No user-facing history UI.
- **Image cache:** `cached_network_image`.
- **Logs:** `talker_flutter` (shake-to-open).
- **Share:** `screenshot` + `share_plus`.
- **Confetti:** `confetti` (the #1 reveal burst).
- **Tests:** `flutter_test`, `mocktail`, **`alchemist`** (goldens — replaces stale `golden_toolkit`).
- **Lints:** **`very_good_analysis`**.

---

## Theme

- **Seed color:** `#6750A4` (Material 3 baseline purple) — generated palette, then overridden with custom neutrals to feel premium, not stock-Material.
- **Mode:** dark-first; light theme generated from same seed.
- **Top-3 tier accents:** gold / silver / bronze gradients with soft glow rings.
- **Frosted-glass surfaces** for sticky search bar and share overlay.
- **Typography:** Fraunces for display numerals + wordmark; Inter for everything else.
- All tokens live in `lib/core/theme/`. **Don't hardcode** colors, sizes, durations, or radii — reference tokens.

---

## Architecture

Feature-first Clean Architecture:

```
lib/
├── core/        # env, errors, http, theme, shared widgets
├── features/
│   ├── ranking/   # data | domain | presentation
│   ├── search/
│   ├── detail/
│   ├── share/
│   └── history/
└── routing/
```

- `data/` — HTTP clients, repositories, prompt builders. No widgets.
- `domain/` — freezed models, sealed state unions. No Flutter imports.
- `presentation/` — screens, widgets, controllers. No raw HTTP.
- All async returns a `Stream` or a `Result<T, AppError>`; never throw across layer boundaries.

---

## Conventions

- **No hardcoded values.** Use the tokens in `lib/core/theme/`.
- **Sealed unions for state** — exhaust them with `switch` patterns.
- **`Result<T, AppError>` for typed errors.** Convert exceptions at boundaries.
- **Cancellable streams.** Every long-running op supports `CancelToken` / `StreamSubscription.cancel()`.
- **Skeletons before spinners.** First paint always renders shape.
- **Riverpod `select`** to avoid rebuilds.
- **GPU-only animations** (`Transform`, `Opacity`, `ImageFiltered`) — no layout thrash in motion.
- **Conventional commits**, small focused commits.
- **No comments that explain WHAT** — only WHY (constraints, invariants, surprises).

---

## Running

**Always use `fvm` to invoke Flutter/Dart** — the project is pinned to Flutter 3.44.0 via `.fvmrc`.

```bash
# install deps + codegen
fvm flutter pub get
fvm dart run build_runner build

# run on iOS simulator with API key
fvm flutter run --dart-define=OPENAI_API_KEY=sk-...

# or use the makefile shortcuts (which prefix fvm for you)
make run OPENAI_API_KEY=sk-...
make gen
make test
make analyze
```

The OpenAI API key **must** come via `--dart-define` — never commit it. The constant lives in `lib/core/env.dart` with a `// FIND-ME: OPENAI_API_KEY` marker per the brief.

---

## Common commands

| Command | What it does |
|---|---|
| `make run OPENAI_API_KEY=sk-...` | iOS run with env vars wired (debug) |
| `make run-release OPENAI_API_KEY=sk-...` | iOS run release (for demo recording) |
| `make test` | unit + widget + golden tests |
| `make gen` | freezed / json_serializable codegen |
| `make gen-watch` | codegen in watch mode |
| `make pods` | `pod install` in `ios/` |
| `make build-ios` | release iOS build (no codesign) |
| `make analyze` | lint via very_good_analysis |
| `make format` | dart format |
| `make clean` | flutter clean + remove codegen artifacts |

---

## Tests

- **Unit:** schema parser, prompt builder.
- **Repository:** fake OpenAI client returning canned SSE.
- **Widget:** each `RankItem.kind` variant renders.
- **Golden:** gold top-3 card.

Add tests when you add behavior. Don't ship untested error paths.

---

## Skill conflicts — project choices win

This project has installed the official `flutter/skills` and `dart-lang/skills` packs (project-scoped, in `.claude/skills/`). Use them as references, but **when a skill's recommendation conflicts with `IDEA.md` or this file, the project spec wins.**

Known conflicts:

| Skill | Skill recommends | This project uses | Why |
|---|---|---|---|
| `flutter-apply-architecture-best-practices` | MVVM with `ChangeNotifier` / `Listenable` | Riverpod v2 (`AsyncNotifier`) | Stream-native, testable async, fits the streaming countdown state machine |

If you spot a new conflict, prefer the spec, and note it in this table.

---

## Keep the docs in sync

When you make changes that affect **architecture, dependencies, stack choices, theming, screen flow, or scope**:
- Update `IDEA.md` (full spec — sections 2–13).
- Update this file (`CLAUDE.md`) if quick-reference info changes.

A `PostToolUse` hook (`.claude/settings.json`) will remind you on edits inside `lib/`, `pubspec.yaml`, `analysis_options.yaml`, or `Makefile`. **Don't ignore it.**
