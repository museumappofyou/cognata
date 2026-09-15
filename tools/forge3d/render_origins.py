#!/usr/bin/env python3
"""Precompute forge3d assets for Cognata's Origins page.

Renders the Pontic-Caspian steppe — the Kurgan-hypothesis Proto-Indo-European
homeland — from the Terrarium-derived heightmap built by ``build_steppe_dem.py``,
using forge3d's GPU path tracer (``hybrid_render_terrain_reference``, ReSTIR +
adaptive accumulation). The dusk sky and depth haze are composed in post from
the depth AOV (see ``_sky_and_haze``).

Stages:
    hero       1536x864 converged still
    turntable  24 orbit frames, 1200x675
    flyover    36 camera-path frames, 1200x675

Frames are rendered one per child process (``--frame``), because the native
ReSTIR validation is flaky under GPU contention and a fresh process retries
cleanly. PNGs land in ``out/``; ``scripts/render_assets.sh`` encodes them into
``assets/forge3d/`` as WebP.

Usage:
    python render_origins.py hero            # stage, with subprocess retries
    python render_origins.py turntable
    python render_origins.py flyover
    python render_origins.py all
    python render_origins.py --frame hero    # single frame (internal use)
"""

from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
import sys
import time
from pathlib import Path

import numpy as np

import forge3d as f3d

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
CACHE = HERE / "cache"
OUT = HERE / "out"

# Crop of the full mosaic: Crimea + Sea of Azov + the Dnieper/Don steppe.
# Rows run north -> south over lon 30..42 / lat 44..50.
CROP = (slice(668, 1470), slice(546, 1456))

SPACING_M = 417.0
EXAGGERATION = 6.0
TURNTABLE_FRAMES = 24
FLYOVER_FRAMES = 36

SUN = dict(
    azimuth_deg=305.0,
    elevation_deg=16.0,
    intensity=5.0,
    color=(1.0, 0.94, 0.86),
)

SEA = np.array([0.05, 0.11, 0.16], dtype=np.float32)
LOWLAND = np.array([0.10, 0.22, 0.11], dtype=np.float32)
STEPPE = np.array([0.42, 0.40, 0.23], dtype=np.float32)
HIGHLAND = np.array([0.86, 0.84, 0.78], dtype=np.float32)


def load_region() -> tuple[np.ndarray, np.ndarray]:
    """Return (elevation_m, sea_depth_m) arrays for the cropped region."""
    dem = np.load(CACHE / "steppe_dem.npy").astype(np.float32)
    crop = dem[CROP]
    depth = np.maximum(-crop, 0.0)
    elevation = np.maximum(crop, 0.0)
    return elevation, depth


def build_albedo(elevation: np.ndarray, depth: np.ndarray) -> np.ndarray:
    """Hypsometric terrain albedo with a depth-shaded sea (linear RGBA)."""
    hi = max(1.0, float(elevation.max()))
    t = elevation / hi
    low = np.clip(t / 0.30, 0.0, 1.0)[..., None]
    mid = np.clip((t - 0.30) / 0.35, 0.0, 1.0)[..., None]
    high = np.clip((t - 0.65) / 0.35, 0.0, 1.0)[..., None]

    rgb = LOWLAND * (1 - low) + STEPPE * low
    rgb = rgb * (1 - mid) + STEPPE * mid
    rgb = rgb * (1 - high) + HIGHLAND * high

    sea_mask = (depth > 0.0)[..., None]
    depth_t = np.clip(depth / max(1.0, float(depth.max())), 0.0, 1.0)[..., None]
    sea_rgb = SEA[None, None, :] * (1.0 - 0.6 * depth_t) + 0.02
    rgb = np.where(sea_mask, sea_rgb, rgb)

    return np.concatenate(
        [rgb.astype(np.float32), np.ones((*rgb.shape[:2], 1), np.float32)],
        axis=-1,
    )


def make_camera(
    *,
    azimuth_deg: float,
    height_m: float,
    distance_m: float,
    look_at: tuple[float, float, float],
    fov_y: float,
    aspect: float,
    exposure: float,
) -> dict:
    rad = math.radians(azimuth_deg)
    origin = (
        look_at[0] + distance_m * math.sin(rad),
        height_m,
        look_at[2] + distance_m * math.cos(rad),
    )
    return f3d.make_camera(
        origin=origin,
        look_at=look_at,
        up=(0.0, 1.0, 0.0),
        fov_y=fov_y,
        aspect=aspect,
        exposure=exposure,
    )


def sun_screen_x(camera_azimuth_deg: float) -> float:
    """Approximate horizontal screen position (0..1) of the sun for a camera."""
    relative = math.radians(SUN["azimuth_deg"] - camera_azimuth_deg)
    return 0.5 + 0.5 * math.sin(relative)


def centre(elevation: np.ndarray) -> tuple[float, float, float]:
    """The path tracer places the heightfield centred on the world origin."""
    return (0.0, float(elevation.max()) * EXAGGERATION * 0.05, 0.0)


def _sky_and_haze(
    rgb: np.ndarray,
    depth: np.ndarray,
    *,
    sun_side: float,
) -> np.ndarray:
    """Composite a designed dusk sky and depth haze over a terrain render.

    The path tracer returns NaN depth where rays miss (sky) and world-unit ray
    distance on terrain. AETHER's GPU sky post proved unreliable on this host,
    so the sky is composed here: a navy-to-gold gradient with a soft solar
    glow, plus exponential haze on distant terrain for aerial perspective.
    """
    h, w = depth.shape
    y = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None]
    x = np.linspace(0.0, 1.0, w, dtype=np.float32)[None, :]

    top = np.array([0.035, 0.065, 0.120], dtype=np.float32)
    mid = np.array([0.090, 0.150, 0.250], dtype=np.float32)
    horizon = np.array([0.560, 0.430, 0.270], dtype=np.float32)

    lower = np.clip(y / 0.72, 0.0, 1.0) ** 1.35
    upper = np.clip((y - 0.72) / 0.28, 0.0, 1.0) ** 1.6
    sky = (
        top[None, None, :] * (1 - lower)[..., None]
        + mid[None, None, :] * lower[..., None]
    )
    sky = sky * (1 - upper)[..., None] + horizon[None, None, :] * upper[..., None]

    glow = np.exp(-(((x - sun_side) / 0.22) ** 2) - (((y - 0.99) / 0.16) ** 2))
    sky = sky + glow[..., None] * np.array([0.30, 0.18, 0.06], dtype=np.float32)

    sky_mask = ~np.isfinite(depth) | (depth <= 0.0)

    haze_distance = 1_200_000.0
    haze = 1.0 - np.exp(-np.nan_to_num(depth, nan=0.0) / haze_distance)
    hazed = (
        rgb * (1.0 - haze)[..., None] + horizon[None, None, :] * haze[..., None]
    )

    return np.where(sky_mask[..., None], sky * 255.0, hazed * 255.0)


def render_frame(
    elevation: np.ndarray,
    albedo: np.ndarray,
    width: int,
    height: int,
    camera: dict,
    *,
    spp: int,
    max_frames: int,
    variance: float,
    sun_side: float,
) -> np.ndarray:
    """One converged frame with composed sky and haze."""
    last_error: Exception | None = None
    result = None
    for attempt in range(4):
        try:
            result = f3d.hybrid_render_terrain_reference(
                elevation,
                width,
                height,
                camera,
                spacing=(SPACING_M, SPACING_M),
                exaggeration=EXAGGERATION,
                albedo_map=albedo,
                albedo_sampling="bilinear",
                sun_azimuth_deg=SUN["azimuth_deg"],
                sun_elevation_deg=SUN["elevation_deg"],
                sun_intensity=SUN["intensity"],
                sun_color=SUN["color"],
                spp=spp,
                min_frames=32,
                max_frames=max_frames,
                variance_threshold=variance,
                seed=7 + attempt,
            )
            if not bool(result.get("converged")):
                raise RuntimeError(f"frame failed to converge at {width}x{height}")
            break
        except RuntimeError as exc:
            last_error = exc
            if "reservoir" not in str(exc) and "did not converge" not in str(exc):
                raise
    if result is None:
        raise RuntimeError(f"frame failed: {last_error}")

    rgb = np.asarray(result["rgba"])[..., :3].astype(np.float32) / 255.0
    depth = np.asarray(result["depth"], dtype=np.float32)
    blended = _sky_and_haze(rgb, depth, sun_side=sun_side)

    plate = np.empty((height, width, 4), dtype=np.uint8)
    plate[..., :3] = np.clip(blended, 0, 255).astype(np.uint8)
    plate[..., 3] = 255
    return plate


# --- frame specs -------------------------------------------------------------


def render_hero_frame() -> None:
    elevation, depth = load_region()
    albedo = build_albedo(elevation, depth)
    camera = make_camera(
        azimuth_deg=0.0,
        height_m=150_000.0,
        distance_m=270_000.0,
        look_at=centre(elevation),
        fov_y=42.0,
        aspect=1536 / 864,
        exposure=1.7,
    )
    plate = render_frame(
        elevation,
        albedo,
        1536,
        864,
        camera,
        spp=4,
        max_frames=512,
        variance=8e-3,
        sun_side=sun_screen_x(0.0),
    )
    OUT.mkdir(parents=True, exist_ok=True)
    f3d.numpy_to_png(OUT / "origins-hero.png", plate[..., :3])


def render_turntable_frame(index: int) -> None:
    elevation, depth = load_region()
    albedo = build_albedo(elevation, depth)
    azimuth = index * (360.0 / TURNTABLE_FRAMES)
    camera = make_camera(
        azimuth_deg=azimuth,
        height_m=200_000.0,
        distance_m=240_000.0,
        look_at=centre(elevation),
        fov_y=44.0,
        aspect=1200 / 675,
        exposure=1.7,
    )
    plate = render_frame(
        elevation,
        albedo,
        1200,
        675,
        camera,
        spp=3,
        max_frames=512,
        variance=1e-2,
        sun_side=sun_screen_x(azimuth),
    )
    frame_dir = OUT / "turntable"
    frame_dir.mkdir(parents=True, exist_ok=True)
    f3d.numpy_to_png(frame_dir / f"turntable_{index:02d}.png", plate[..., :3])


def render_flyover_frame(index: int) -> None:
    elevation, depth = load_region()
    albedo = build_albedo(elevation, depth)
    t = index / (FLYOVER_FRAMES - 1)
    wave = 0.5 - 0.5 * math.cos(2.0 * math.pi * t)
    azimuth = -14.0 + 22.0 * math.sin(2.0 * math.pi * t)
    height = 90_000.0 + 130_000.0 * wave
    distance = 300_000.0 - 70_000.0 * wave
    camera = make_camera(
        azimuth_deg=azimuth % 360.0,
        height_m=height,
        distance_m=distance,
        look_at=centre(elevation),
        fov_y=44.0,
        aspect=1200 / 675,
        exposure=1.7,
    )
    plate = render_frame(
        elevation,
        albedo,
        1200,
        675,
        camera,
        spp=3,
        max_frames=512,
        variance=1e-2,
        sun_side=sun_screen_x(azimuth),
    )
    frame_dir = OUT / "flyover"
    frame_dir.mkdir(parents=True, exist_ok=True)
    f3d.numpy_to_png(frame_dir / f"flyover_{index:02d}.png", plate[..., :3])


# --- stage orchestration -----------------------------------------------------


def _run_frame(spec: str, attempts: int = 60) -> None:
    """Render one frame in a child process, retrying on transient failures."""
    last_stderr = ""
    for attempt in range(attempts):
        proc = subprocess.run(
            [sys.executable, str(Path(__file__).resolve()), "--frame", spec],
            capture_output=True,
            text=True,
        )
        if proc.returncode == 0:
            return
        last_stderr = proc.stderr.strip()[-400:]
        if (attempt + 1) % 5 == 0:
            print(f"[render] {spec}: attempt {attempt + 1} failed", flush=True)
        time.sleep(1.5)
    raise SystemExit(f"[render] {spec} failed after {attempts} attempts:\n{last_stderr}")


def _skip_existing(target: Path) -> bool:
    """Resume support: leave finished frames alone unless FORGE3D_FORCE=1."""
    return target.exists() and os.environ.get("FORGE3D_FORCE") != "1"


def stage_hero() -> None:
    if _skip_existing(OUT / "origins-hero.png"):
        print("[render] hero: already rendered (FORGE3D_FORCE=1 to redo)", flush=True)
        return
    _run_frame("hero")


def stage_turntable() -> None:
    for i in range(TURNTABLE_FRAMES):
        target = OUT / "turntable" / f"turntable_{i:02d}.png"
        if _skip_existing(target):
            continue
        started = time.time()
        _run_frame(f"turntable:{i}")
        print(
            f"[render] turntable {i + 1}/{TURNTABLE_FRAMES} in {time.time() - started:.1f}s",
            flush=True,
        )


def stage_flyover() -> None:
    for i in range(FLYOVER_FRAMES):
        target = OUT / "flyover" / f"flyover_{i:02d}.png"
        if _skip_existing(target):
            continue
        started = time.time()
        _run_frame(f"flyover:{i}")
        print(
            f"[render] flyover {i + 1}/{FLYOVER_FRAMES} in {time.time() - started:.1f}s",
            flush=True,
        )


def render_single_frame(spec: str) -> None:
    stage, _, index = spec.partition(":")
    if stage == "hero":
        render_hero_frame()
    elif stage == "turntable":
        render_turntable_frame(int(index))
    elif stage == "flyover":
        render_flyover_frame(int(index))
    else:
        raise SystemExit(f"unknown frame spec: {spec}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "stage",
        choices=["hero", "turntable", "flyover", "all"],
        nargs="?",
        default="hero",
    )
    parser.add_argument("--frame", help="render a single frame: hero | turntable:N | flyover:N")
    args = parser.parse_args()

    if not (CACHE / "steppe_dem.npy").exists():
        raise SystemExit(
            "missing cache/steppe_dem.npy — run build_steppe_dem.py first"
        )

    if args.frame:
        render_single_frame(args.frame)
        return

    meta = json.loads((CACHE / "steppe_dem.json").read_text())
    elevation, depth = load_region()
    print(
        f"[render] region {elevation.shape} relief {elevation.max():.0f} m, "
        f"sea depth {depth.max():.0f} m ({meta['attribution']})",
        flush=True,
    )

    if args.stage in {"hero", "all"}:
        stage_hero()
    if args.stage in {"turntable", "all"}:
        stage_turntable()
    if args.stage in {"flyover", "all"}:
        stage_flyover()


if __name__ == "__main__":
    main()
