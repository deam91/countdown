# Design Prompt — Countdown (Flutter iOS)

> Paste the block below into Claude Design (or any high-fidelity design AI). It's self-contained — every token, dimension, screen, and motion note is inline; the AI doesn't need outside context.

---

```
You are a senior product designer creating high-fidelity mobile mockups for an iOS app called **Countdown**. Produce all 7 screens described below, arranged horizontally so a reviewer can trace the user flow left to right.

# The product
Countdown turns any "give me the top N…" question into a cinematic streaming reveal. The user types or speaks a ranking question (e.g., "Top 10 ramen in Tokyo", "Best entrepreneurship books"); the app calls GPT-4o-mini, streams results back, and reveals items #10 → #1 with rich, adaptive cards. Each card adapts to its kind: PLACES show a mini-map and pin, BOOKS show a cover + author + stars, PEOPLE show a circular portrait + tagline, GENERIC items show a square image. Top 3 ranks get gold/silver/bronze tier treatment. Rank #1 triggers a confetti burst.

# Design philosophy
- **Editorial, magazine-like.** Not a tech demo. The reveal feels like opening a curated list, not parsing JSON.
- **Dark-first, premium.** Deep violet-tinted black surfaces. Frosted glass for floating panels. Soft glows on hero elements.
- **Cinematic motion.** Cards reveal with scale + blur-in. The #1 moment warms the entire background subtly.
- **One serif accent.** Fraunces (display serif) carries the rank numerals; everything else is Inter (clean sans). That contrast IS the visual personality.
- **Token-driven.** Every value below is a token. Don't invent off-token sizes, colors, or radii.

# Visual tokens

## Color (dark theme — primary mode)
- brand.primary: #6750A4
- brand.primaryContainer: #4F378B
- brand.secondary: #9A82DB
- brand.tertiary: #EFB8C8
- surface.base: #141218 (app background, slight violet tint)
- surface.elevated: #1D1B20 (cards)
- surface.glass: rgba(38, 35, 42, 0.70) + 24px backdrop blur (sticky bars, overlays)
- surface.outline: #49454F (1px subtle outlines)
- text.primary: #E6E0E9
- text.secondary: #CAC4D0
- text.tertiary: #938F99
- state.error: #F2B8B5

## Tier accents (ranks 1–3 only; ranks 4+ use a neutral purple-tinted outline)
- Rank 1 — Gold:   gradient #F5C46A → #C9892A; outer glow warm amber, 24px blur
- Rank 2 — Silver: gradient #E5E4EA → #A6A4B0; outer glow cool white, 20px blur
- Rank 3 — Bronze: gradient #D89B7B → #9B5A3B; outer glow warm copper, 16px blur

## Typography
- Display: **Fraunces** (variable serif) — rank numerals (72sp on top-3, 48sp on others) and the wordmark.
- UI: **Inter** (variable sans) — everything else.
- Scale (semantic):
  - display.l   Fraunces 72 / 600  (top-3 rank numerals)
  - display.m   Fraunces 48 / 500  (rank 4-N numerals, share-card titles)
  - headline.l  Inter    28 / 600  (search prompt)
  - title.l     Inter    20 / 600  (card titles)
  - title.m     Inter    17 / 600  (detail headings)
  - body.l      Inter    16 / 400
  - body.m      Inter    14 / 400  ("why it ranks" copy)
  - label.l     Inter    13 / 500  (buttons, badges)
  - caption     Inter    12 / 400 / text.secondary

## Spacing & radius
- Spacing scale: 4, 8, 12, 16, 20, 24, 32, 48. No arbitrary values.
- Radius: cards 20 · pills 999 · buttons 16 · inputs 28 (large rounded search bar) · in-card images 12.

## Elevation
- Never shadow alone. Pair elevation with a 1px outline at surface.outline @ 50% so things read on dark.
- Glass surfaces = 24px backdrop blur + 70% surface fill.

## Iconography
- Lucide stroke icons (1.5px stroke). 24px default; 20px in compact rows; 16px in chips. Icons inherit text.secondary unless interactive (then brand.secondary).

# Viewport
iPhone 15 Pro: **393 × 852pt**, safe-area top 59pt / bottom 34pt.

# Screens to deliver (all 7, horizontally arranged)

## 1. Splash
- Full surface.base.
- Centered Fraunces wordmark "Countdown" in display.m, brand.tertiary.
- A single brand.primary dot sits after the "n", pulsing scale 1.0 → 1.15 every 1.2s.

## 2. Search (idle)
- Headline (headline.l, text.primary), 32pt below safe-area top: "What do you want ranked?"
- Large glass input bar below: 56pt tall, radius 28, surface.glass fill, 1px outline.
  - Left: Lucide `Search`, 20px, text.secondary.
  - Center: rotating placeholder (body.l / text.tertiary). Show "Top 10 ramen in Tokyo".
  - Right: Lucide `Mic`, 24px, brand.secondary.
- Two rows of 3 example query chips (pill, radius 999, 36pt tall, 12px H padding, surface.elevated bg + 1px outline, label.l text.secondary):
  - "Top 10 ramen in Tokyo"
  - "Best entrepreneurship books"
  - "Most underrated horror films"
  - "Greatest tennis players"
  - "Top sci-fi novels of the 2020s"
  - "Best beaches in Portugal"
- Bottom (above safe-area): caption "Powered by GPT-4o-mini · Images by Unsplash" centered.

## 3. Ranking — streaming state (the centerpiece)
Show **7 visible cards**, mixing kinds.

### App bar (sticky frosted glass)
- Left: Lucide `ChevronLeft`, 24px text.secondary.
- Center: shortened query, label.l italic text.secondary — "Top 10 ramen in Tokyo".
- Right: Lucide `Share2`, 24px, text.tertiary (disabled — not yet done).

### Status sub-header (just below app bar)
Three animated dots in brand.secondary + caption "Revealing 4 of 10…" in text.secondary.

### Card list
Vertical, 16px horizontal padding, 12px gap. Each card ~140pt tall, radius 20.

**Card anatomy** (read left-to-right):
- Background: surface.elevated, 1px outline surface.outline @ 50% (ranks 4+ only — top-3 get a 2px tier gradient ring instead, plus the outer glow).
- **Left strip**: 80pt wide, vertical gradient bar (tier color for top 3, brand.primary @ 30% for others). Centered in the strip: rank numeral in Fraunces — display.l for top 3, display.m for 4+.
- **Main content area** (padding 16px):
  - Top row: tier badge pill (top-3 only). Gold/silver/bronze pill, label.l, brand.onPrimary text, e.g., "GOLD".
  - Title: title.l, text.primary, one line, ellipsis.
  - Sub-line: kind-specific (see below).
  - "Why it ranks": body.m, text.secondary, one line, ellipsis.
  - Score bar: 4px tall, full width inside content area, fills 0 → score%, tier color or brand.primary.
- **Right area**: 96 × 96 image, radius 12 (overridden by kind — see below).

### Card kind variants (mix across the 7 visible cards)
- **PlaceCard**: sub-line is the address with Lucide `MapPin` (14px text.secondary). Below the title row, a 56pt-tall map strip (desaturated purple-gray OpenStreetMap tile) with a single brand.primary pin glyph dropped in the center.
- **BookCard**: image is 3:4 aspect (book cover). Sub-line shows "by {author} · {year}" in body.m text.secondary + a row of 5 star glyphs (filled by score / 2).
- **PersonCard**: image is circular avatar (radius 999). Sub-line is the tagline in italic body.m text.secondary.
- **GenericCard**: square 96×96 image, no extra sub-line — just title + why-it-ranks + score bar.

### Skeleton slots
Below the visible cards, show **3 skeleton card slots**: same shape, but image area, title, and copy replaced with shimmer-blocks in surface.outline.

## 4. Ranking — #1 reveal moment
Same layout as Screen 3, but:
- Show the top-3 cards expanded, **#1 the largest** (180pt tall).
- #1 has the gold gradient ring (2px) replacing the outline, plus the outer warm-amber glow (24px blur).
- **Confetti burst** overlays #1 from behind — ~12 gold particles mid-air with short motion trails.
- The screen background warms subtly — a 6% gold radial gradient bleeding from the top of #1.
- **Sticky bottom glass bar**: two pill buttons side by side.
  - "Share" — filled brand.primary, brand.onPrimary text, Lucide `Share2` 16px leading.
  - "Ask another" — outlined surface.outline, text.primary, Lucide `RotateCw` 16px leading.

## 5. Detail screen (for a place item)
- **Hero image** at the top, 320pt tall, full-bleed, gentle bottom gradient fade into surface.base.
- Overlay on the image (bottom-left): rank numeral (Fraunces display.l, gold gradient text fill) + tier badge pill.
- Below the hero:
  - **Title** (title.l, text.primary).
  - **Score row**: large score number (display.m, gold gradient text) + "/ 10" + horizontal star row.
  - **Why it ranks** in body.l, text.primary, no truncation, 3-4 lines.
  - Section header **"Location"** (title.m) + a full-width 200pt map embed (rounded 20), brand.primary pin centered.
  - **External link chips row** (horizontal scroll): "Open in Maps", "Search on Google", "Wikipedia". Pills, outlined, label.l text.primary, Lucide `ExternalLink` 16px trailing.
- Sticky bottom button: **"Re-roll this rank"** — outlined brand.secondary, full width minus 16px each side.

## 6. Share screen (9:16 export preview)
- Centered: a preview of the exported image inside a phone frame.
- 9:16 composition: header strip with the query + "Countdown" wordmark watermark bottom-right corner.
- All 10 cards stacked at small scale (mini-cards = rank numeral + title + score bar only).
- Top-3 mini-cards retain their tier color treatment.
- Background of the export: subtle brand.primary radial gradient from top center.
- Below the preview: a single **"Share"** button (filled brand.primary, full width).

## 7. Error state (rate limited / HTTP 429)
- Centered illustrated empty state:
  - Above: a hand-drawn-style flame illustration, brand.secondary stroke, no fill, ~120pt tall.
  - **Title**: headline.l, text.primary, centered — "Easy, tiger".
  - **Body**: body.l, text.secondary, centered, max-width 280pt — "GPT is asking us to slow down. Try again in {N}s."
  - **Pill button** (outlined surface.outline, label.l text.primary): "Retry in 12s" — the number animates down.
- App bar present at top so the user can navigate back.

# Motion annotations
For each screen, add small annotation arrows/labels indicating:
- **Card reveal**: opacity 0→1, scale 0.95→1.0, blur 8→0px. 280ms easeOutCubic (700ms easeOutQuart for #1).
- **Stagger**: 60ms between cards.
- **Score bar**: fills 200ms after card lands.
- **Haptics**: light on reveal; medium on #1.
- **#1 background warm tint**: 800ms in, holds 400ms, 800ms out.
- **Confetti**: 1.2s lifecycle, gravity-affected, fade-out in the last 400ms.

# Output format
Deliver all 7 screens as a single horizontal artboard:
**Splash → Search → Ranking (streaming) → #1 reveal → Detail → Share → Error**

If producing HTML mockups:
- Each screen as a 393 × 852 device-frame in a horizontal row, 64px gap between frames, on a #0A0A0A page background.
- Label each frame in a caption above (Inter 14, text.tertiary).
- Embed Fraunces and Inter from Google Fonts.
- Lucide icons via CDN (lucide.dev).
- Card images: solid color blocks tinted with a desaturated photo gradient — no real photos.

If producing Figma:
- One page, 7 frames horizontally.
- Plus a token sheet at the far right: color swatches, type ramp, spacing scale, radius scale — for engineering handoff.

# Things to avoid
- Material default buttons or app bars. Everything is bespoke.
- Stock blue accents — the only blue allowed is incidental in map tiles.
- Drop shadows without paired outlines on dark surfaces (they read as fuzz).
- Square card corners. Everything is radius 20+.
- Generic AI-app aesthetics (purple-on-purple-on-purple, neon gradients, plain glass). Stay editorial.
```

---

## Notes for use

- **Where to paste:** Claude Design, claude.ai with frontend-design skill, v0.dev, or any high-fidelity design AI. The block is self-contained.
- **What you'll get back:** a horizontal artboard of 7 mobile mockups + (in Figma mode) a token reference sheet.
- **Iteration tips:**
  - If outputs feel too generic, paste the "Things to avoid" section again as a follow-up.
  - If the AI defaults to Material 3 components, add: "Treat M3 as inspiration only — every component is bespoke, designed from these tokens."
  - For variants (light theme, accessibility audit, alternate copy), ask in follow-up prompts referencing this base.
