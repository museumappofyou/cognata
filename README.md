# Cognata — The Language Decryption Engine

> You already know 3,000 words in German, Spanish, Italian and French —
> you just don't know the cipher yet.

Cognata is a cross-platform Flutter app about **linguistic cryptography**:
Proto-Indo-European sound laws (Grimm's Law, the High German shift) turned into
a daily puzzle, a rule matrix, and a word-family atlas. The Origins page adds
precomputed 3D terrain renders of the Pontic–Caspian steppe — the homeland the
language family started from.

## Features

- **The Daily Cognate** — one mystery word a day, three guesses, escalating
  hints, streaks, shareable result. State lives in `shared_preferences`.
- **The Decryption Matrix** — the ten most productive sound laws for
  English ↔ German and English ↔ Spanish/Latin, with one-tap Anki (TSV) export.
- **The Kinship Tree** — a word's cousins across fifteen languages, drawn with
  a custom painter and pannable/zoomable (`InteractiveViewer`).
- **Origins** — a path-traced steppe diorama: hero render, a 24-frame
  scrubbable turntable, and an animated flyover, all precomputed with
  [forge3d](https://github.com/milos-agathon/forge3d).

## Platforms

iOS, Android, macOS, web, Windows and Linux. Web output (`flutter build web`)
replaces the project's original Next.js site.

## Getting started

```bash
flutter pub get
flutter run            # pick a device, e.g. -d macos, -d chrome, -d ios
```

### Checks

```bash
flutter analyze
flutter test
```

## Precomputed 3D assets

The Origins content is baked offline — the app needs no GPU or Python at
runtime. Frames live in `assets/forge3d/` (WebP).

To regenerate them (needs Python 3.10+, a wgpu-capable GPU, and
`cwebp`/`img2webp` from `brew install webp`):

```bash
scripts/render_assets.sh
```

See [`tools/forge3d/README.md`](tools/forge3d/README.md) for the pipeline and
data attribution (Mapzen Terrarium elevation, AWS Open Data).

## Project layout

```
lib/
  main.dart                  app entry, data loading
  src/app/                   adaptive shell + scope (nav, DI)
  src/core/                  models, sound-law logic, record store
  src/data/                  bundled JSON loader
  src/pages/                 home, daily, matrix, tree, origins, about
  src/theme/                 Cognata colors, fonts, ThemeData
  src/widgets/               cards, pills, page body/header
assets/
  data/                      soundLaws.json, familyTrees.json, puzzles.json
  fonts/                     Playfair Display + Merriweather (variable)
  forge3d/                   precomputed terrain renders
tools/forge3d/               offline render pipeline (Python + forge3d)
scripts/render_assets.sh     one-command asset rebuild
```

## Credits & caveats

Etymologies are curated from standard historical-linguistics references and the
Wiktionary etymology community; the [etymology-db
project](https://github.com/droher/etymology-db) has the full derivation graph.
Sound laws are regular, but real words wander — the notes say so where we know.
