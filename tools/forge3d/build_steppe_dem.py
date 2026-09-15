#!/usr/bin/env python3
"""Assemble a float32 terrain heightmap of the Pontic-Caspian steppe.

Downloads Mapzen Terrarium elevation tiles (AWS Open Data,
``elevation-tiles-prod``; SRTM/GMTED/ETOPO derived) for the region around the
Kurgan-hypothesis homeland, mosaics them into a Web Mercator grid (EPSG:3857),
downsamples 2x, and writes ``cache/steppe_dem.npy`` plus a metadata sidecar.

Usage:
    python build_steppe_dem.py [--zoom 9] [--region 30,44,42,50]
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import math
import tempfile
import urllib.request
from pathlib import Path

import numpy as np

import forge3d as f3d

TILE_URL = "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"
TILE_SIZE = 256
CACHE = Path(__file__).resolve().parent / "cache"


def deg2num(lat: float, lon: float, z: int) -> tuple[float, float]:
    n = 2.0**z
    x = (lon + 180.0) / 360.0 * n
    lat_r = math.radians(lat)
    y = (1.0 - math.asinh(math.tan(lat_r)) / math.pi) / 2.0 * n
    return x, y


def num2deg(x: float, y: float, z: int) -> tuple[float, float]:
    n = 2.0**z
    lon = x / n * 360.0 - 180.0
    lat = math.degrees(math.atan(math.sinh(math.pi * (1.0 - 2.0 * y / n))))
    return lat, lon


def fetch_tile(z: int, x: int, y: int) -> np.ndarray:
    url = TILE_URL.format(z=z, x=x, y=y)
    with urllib.request.urlopen(url, timeout=60) as response:
        raw = response.read()
    with tempfile.NamedTemporaryFile(suffix=".png", delete=True) as tmp:
        tmp.write(raw)
        tmp.flush()
        rgba = f3d.png_to_numpy(tmp.name)
    arr = np.asarray(rgba)
    if arr.ndim != 3 or arr.shape[2] < 3:
        raise ValueError(f"unexpected tile shape {arr.shape} for {url}")
    return arr[..., :3].astype(np.float32)


def terrarium_to_elevation(rgb: np.ndarray) -> np.ndarray:
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return (r * 256.0 + g + b / 256.0) - 32768.0


def build(z: int, region: tuple[float, float, float, float]) -> tuple[np.ndarray, dict]:
    lon_min, lat_min, lon_max, lat_max = region

    x0f, y0f = deg2num(lat_max, lon_min, z)
    x1f, y1f = deg2num(lat_min, lon_max, z)
    x0, y0 = math.floor(x0f), math.floor(y0f)
    x1, y1 = math.floor(x1f), math.floor(y1f)

    cols = x1 - x0 + 1
    rows = y1 - y0 + 1
    print(f"[dem] z={z} tiles={cols}x{rows} ({cols * rows})", flush=True)

    mosaic = np.zeros((rows * TILE_SIZE, cols * TILE_SIZE), dtype=np.float32)
    missing = 0
    done = 0

    def load(tile: tuple[int, int]) -> tuple[int, int, np.ndarray | None]:
        tx, ty = tile
        try:
            rgb = fetch_tile(z, tx, ty)
            return tx, ty, terrarium_to_elevation(rgb)
        except Exception as exc:  # noqa: BLE001 - report and keep going
            print(f"[dem] tile {z}/{tx}/{ty} failed: {exc}", flush=True)
            return tx, ty, None

    tiles = [(x0 + i, y0 + j) for j in range(rows) for i in range(cols)]
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as pool:
        for tx, ty, band in pool.map(load, tiles):
            done += 1
            if band is None:
                missing += 1
                continue
            px = (tx - x0) * TILE_SIZE
            py = (ty - y0) * TILE_SIZE
            mosaic[py : py + TILE_SIZE, px : px + TILE_SIZE] = band
            if done % 40 == 0 or done == len(tiles):
                print(f"[dem] {done}/{len(tiles)} tiles", flush=True)

    # Crop to the exact requested bounds.
    px0 = round((x0f - x0) * TILE_SIZE)
    py0 = round((y0f - y0) * TILE_SIZE)
    px1 = round((x1f - x0) * TILE_SIZE)
    py1 = round((y1f - y0) * TILE_SIZE)
    cropped = mosaic[py0:py1, px0:px1]

    # 2x area-average downsample for render-friendly resolution.
    h, w = cropped.shape
    h2, w2 = h - h % 2, w - w % 2
    reduced = cropped[:h2, :w2].reshape(h2 // 2, 2, w2 // 2, 2).mean(axis=(1, 3))

    meta = {
        "source": "Mapzen Terrarium tiles (AWS Open Data elevation-tiles-prod)",
        "attribution": "Mapzen / AWS Open Data; SRTM, GMTED, ETOPO derived",
        "zoom": z,
        "bounds_wgs84": {
            "lon_min": lon_min,
            "lat_min": lat_min,
            "lon_max": lon_max,
            "lat_max": lat_max,
        },
        "crs": "EPSG:3857",
        "shape": list(reduced.shape),
        "elevation_min_m": float(reduced.min()),
        "elevation_max_m": float(reduced.max()),
        "missing_tiles": missing,
        "meters_per_pixel_approx": 111_320.0
        * (lon_max - lon_min)
        / max(1, reduced.shape[1]),
    }
    return reduced, meta


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--zoom", type=int, default=9)
    parser.add_argument(
        "--region",
        type=str,
        default="30,44,42,50",
        help="lon_min,lat_min,lon_max,lat_max",
    )
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    region = tuple(float(part) for part in args.region.split(","))
    if len(region) != 4:
        raise SystemExit("--region needs lon_min,lat_min,lon_max,lat_max")

    CACHE.mkdir(parents=True, exist_ok=True)
    dem_path = CACHE / "steppe_dem.npy"
    meta_path = CACHE / "steppe_dem.json"

    if dem_path.exists() and meta_path.exists() and not args.force:
        print(f"[dem] cached: {dem_path}")
        return

    dem, meta = build(args.zoom, region)  # type: ignore[arg-type]
    np.save(dem_path, dem)
    meta_path.write_text(json.dumps(meta, indent=2) + "\n")
    print(
        f"[dem] wrote {dem_path} shape={dem.shape} "
        f"range=[{meta['elevation_min_m']:.0f}, {meta['elevation_max_m']:.0f}] m "
        f"missing_tiles={meta['missing_tiles']}"
    )


if __name__ == "__main__":
    main()
