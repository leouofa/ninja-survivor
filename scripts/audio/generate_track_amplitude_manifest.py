#!/usr/bin/env python3
"""
generate_track_amplitude_manifest.py
====================================
Analyzes all MP3 audio tracks in ninja-survivor/tracks/ using ffmpeg to measure
RMS amplitude (mean volume), peak volume, and dynamic range.

Computes a deterministic, idempotent seed for each track and assigns:
- Procedural terrain height parameters
- Voronoi frequency scale
- Cyberpunk neon color palette (Primary, Secondary, Ambient)

Outputs: assets/data/tracks_amplitude_manifest.json
"""

import os
import re
import json
import hashlib
import subprocess
from concurrent.futures import ThreadPoolExecutor

TRACKS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../tracks"))
OUTPUT_JSON = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../assets/data/tracks_amplitude_manifest.json"))

# Curated Cyberpunk / Synthwave Color Themes
THEMES = [
    {
        "name": "Neon Cyan & Magenta",
        "primary": [0.0, 0.95, 1.0, 1.0],      # Cyber Cyan
        "secondary": [1.0, 0.08, 0.58, 1.0],   # Electric Pink
        "ambient": [0.03, 0.02, 0.08, 1.0]     # Deep Indigo
    },
    {
        "name": "Solar Crimson & Gold",
        "primary": [1.0, 0.85, 0.12, 1.0],    # Cyber Gold
        "secondary": [1.0, 0.22, 0.15, 1.0],   # Solar Crimson
        "ambient": [0.08, 0.02, 0.03, 1.0]     # Dark Ruby
    },
    {
        "name": "Jade Emerald & Azure",
        "primary": [0.0, 1.0, 0.45, 1.0],      # Vibrant Emerald
        "secondary": [0.0, 0.65, 1.0, 1.0],    # Azure Blue
        "ambient": [0.01, 0.05, 0.04, 1.0]     # Dark Jade
    },
    {
        "name": "Electric Violet & Teal",
        "primary": [0.75, 0.2, 1.0, 1.0],      # Electric Violet
        "secondary": [0.0, 0.9, 0.8, 1.0],     # Synth Teal
        "ambient": [0.04, 0.01, 0.07, 1.0]     # Dark Amethyst
    },
    {
        "name": "Pharaoh Amber & Lapis",
        "primary": [1.0, 0.65, 0.1, 1.0],      # Amber Gold
        "secondary": [0.15, 0.4, 1.0, 1.0],    # Royal Lapis
        "ambient": [0.05, 0.03, 0.02, 1.0]     # Dark Sand
    },
    {
        "name": "Glitch Acid & Toxic Lime",
        "primary": [0.55, 1.0, 0.0, 1.0],      # Toxic Lime
        "secondary": [0.95, 0.1, 0.95, 1.0],   # Glitch Magenta
        "ambient": [0.02, 0.04, 0.02, 1.0]     # Dark Matrix
    }
]

def analyze_track(file_path):
    file_name = os.path.basename(file_path)
    title = os.path.splitext(file_name)[0]
    
    # 1. Measure volume stats using ffmpeg volumedetect
    cmd = [
        "ffmpeg", "-i", file_path,
        "-af", "volumedetect",
        "-vn", "-sn", "-dn",
        "-f", "null", "/dev/null"
    ]
    result = subprocess.run(cmd, stderr=subprocess.PIPE, stdout=subprocess.DEVNULL, text=True)
    stderr = result.stderr
    
    mean_match = re.search(r"mean_volume:\s*(-?[\d\.]+)\s*dB", stderr)
    max_match = re.search(r"max_volume:\s*(-?[\d\.]+)\s*dB", stderr)
    
    mean_db = float(mean_match.group(1)) if mean_match else -16.0
    max_db = float(max_match.group(1)) if max_match else 0.0
    dynamic_range_db = abs(max_db - mean_db)
    
    # 2. Compute audio waveform hash & deterministic 64-bit integer seed
    # Read first 64KB + mid 64KB + file size to get an idempotent fingerprint
    with open(file_path, "rb") as f:
        f.seek(0, os.SEEK_END)
        size = f.tell()
        f.seek(0)
        head = f.read(65536)
        mid_pos = max(0, size // 2 - 32768)
        f.seek(mid_pos)
        mid = f.read(65536)
        
    hasher = hashlib.sha256()
    hasher.update(title.encode("utf-8"))
    hasher.update(head)
    hasher.update(mid)
    hasher.update(f"{mean_db:.2f}:{max_db:.2f}".encode("utf-8"))
    digest = hasher.hexdigest()
    
    # Extract 64-bit unsigned integer seed
    seed = int(digest[:16], 16) & 0x7FFFFFFF  # 31-bit positive int compatible with Godot int
    
    # 3. Calculate normalized energy [0.0, 1.0]
    # Typically mean_db is between -24.0 (quiet) and -8.0 (very loud/compressed)
    norm_energy = min(max((mean_db - (-24.0)) / 16.0, 0.0), 1.0)
    
    # 4. Determine height variability & Voronoi features
    # Higher dynamic range / energy -> higher terrain variability
    height_scale = round(1.2 + (dynamic_range_db / 20.0) * 0.9 + norm_energy * 0.4, 2)
    height_scale = min(max(height_scale, 1.4), 2.3) # clamp between 1.4m and 2.3m
    
    # Voronoi cell scale (frequency across 160m)
    voronoi_scale = round(0.045 + (seed % 100) * 0.0003, 4)
    
    # 5. Deterministically assign color palette
    theme_idx = seed % len(THEMES)
    theme = THEMES[theme_idx]
    
    return {
        "title": title,
        "file_name": file_name,
        "rms_db": mean_db,
        "max_db": max_db,
        "dynamic_range_db": round(dynamic_range_db, 2),
        "normalized_energy": round(norm_energy, 3),
        "seed": seed,
        "height_scale": height_scale,
        "voronoi_scale": voronoi_scale,
        "palette_name": theme["name"],
        "primary_color": theme["primary"],
        "secondary_color": theme["secondary"],
        "ambient_color": theme["ambient"]
    }

def main():
    print(f"Analyzing tracks in {TRACKS_DIR}...")
    track_files = [
        os.path.join(TRACKS_DIR, f)
        for f in os.listdir(TRACKS_DIR)
        if f.endswith(".mp3")
    ]
    track_files.sort()
    
    print(f"Found {len(track_files)} MP3 tracks. Processing in parallel...")
    manifest = {}
    
    with ThreadPoolExecutor(max_workers=8) as executor:
        results = list(executor.map(analyze_track, track_files))
        
    for res in results:
        manifest[res["title"]] = res
        print(f"  • {res['title']}: Seed={res['seed']}, RMS={res['rms_db']}dB, Height={res['height_scale']}m, Theme={res['palette_name']}")
        
    os.makedirs(os.path.dirname(OUTPUT_JSON), exist_ok=True)
    with open(OUTPUT_JSON, "w") as f:
        json.dump(manifest, f, indent=2)
        
    print(f"\nSuccessfully generated amplitude manifest for {len(manifest)} tracks at:\n{OUTPUT_JSON}")

if __name__ == "__main__":
    main()
