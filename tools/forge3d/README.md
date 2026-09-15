# forge3d precompute pipeline

Offline render farm for the **Origins** page. The Flutter app only consumes the
encoded WebP files in `assets/forge3d/`; Python never runs at app runtime.

## What gets rendered

The Pontic–Caspian steppe — the Kurgan-hypothesis Proto-Indo-European
homeland — the window lon 30–42 °E / lat 44–50 °N, covering the Black Sea
north shore, Crimea, the Sea of Azov, and the Dnieper/Don steppe.

| Asset | Stage | Size |
| --- | --- | --- |
| `origins-hero.webp` | `hero` | 2560×1440, path-traced, 4 spp |
| `turntable_00..23.webp` | `turntable` | 24 × 1200×675 orbit frames |
| `origins-flyover.webp` | `flyover` | 36 × 1200×675 animated loop |

## Pipeline

1. **`build_steppe_dem.py`** — downloads Mapzen Terrarium elevation tiles
   (AWS Open Data `elevation-tiles-prod`, SRTM/GMTED/ETOPO derived) for the
   region, mosaics them into an EPSG:3857 grid, downsamples 2× and writes
   `cache/steppe_dem.npy` (~417 m/px ground resolution).
2. **`render_origins.py`** — crops Crimea/Azov, builds a hypsometric albedo
   (with depth-shaded sea), and path-traces every frame through forge3d's
   `hybrid_render_terrain_reference` (GPU path tracer, ReSTIR, adaptive
   accumulation to a per-frame variance threshold). The dusk sky and the
   aerial-perspective haze are composed in post from the depth AOV: forge3d's
   AETHER GPU sky post was unreliable on this host (per-tile exposure seams
   and intermittent reservoir errors under GPU contention), and the composed
   sky matches the app's palette exactly. Each frame is a real converged
   render — no placeholder geometry, no painted terrain.
3. **`../../scripts/render_assets.sh`** — glues it together and encodes the
   PNG frames to WebP (`cwebp`, `img2webp`).

## Run it

```bash
scripts/render_assets.sh          # full pipeline (tens of minutes; GPU-bound)
scripts/render_assets.sh hero     # one stage at a time
```

Frames are rendered one per child process: the native ReSTIR validation is
occasionally flaky under GPU contention, and a fresh process retries cleanly
(12 attempts with backoff per frame).

The first run creates `.venv/` and installs `forge3d==1.36.0` (see
`requirements.txt`). Rendering needs a wgpu adapter — Metal on macOS
(`device_probe()` reports `Apple M1 Pro`, Metal). Encoding needs
`cwebp`/`img2webp` (`brew install webp`).

Working artifacts (`cache/`, `out/`, `.venv/`) are git-ignored; only the WebP
outputs in `assets/forge3d/` are committed.

## Data attribution

- Elevation: Mapzen Terrarium tiles via AWS Open Data; SRTM, GMTED and ETOPO
  derived.
- Rendering: [forge3d](https://github.com/milos-agathon/forge3d) (Apache-2.0 OR
  MIT); only core, non-Pro features are used.

The renderer is path-traced and converges per frame (variance threshold), so
every committed frame is a real converged render — no placeholders.

Known artifact: at these sample counts the ReSTIR/probe sampling leaves soft
low-frequency mottling over flat areas (visible as cloud-shadow-like patches
on the sea). Raise `spp` in `render_origins.py` to reduce it; the committed
frames intentionally keep render times sane under GPU contention.
