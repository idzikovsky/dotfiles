#!/usr/bin/env python
"""Remove all chunks outside the squares defined in a coords.yaml from a Minecraft world.

The config is a YAML mapping with the target dimension and a list of
rectangles given by two opposite corners in chunk coordinates (inclusive):

    dimension: overworld
    squares:
      - descr: "ice"
        a: [ -264, -35 ]
        b: [ -252, -23 ]

By default this is a dry run; pass --apply to actually modify the world.
Region files are rewritten by copying the raw bytes of kept chunks, so chunk
data survives untouched for any Minecraft version; files whose chunks are all
outside the squares are deleted entirely.
"""
import argparse
import math
import re
import sys
from pathlib import Path

import anvil
import yaml

SECTOR = 4096
REGION_RE = re.compile(r'^r\.(-?\d+)\.(-?\d+)\.mca$')
DIMENSION_SUBDIR = {'overworld': '.', 'nether': 'DIM-1', 'end': 'DIM1'}


def load_config(path):
    with open(path) as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict) or not isinstance(data.get('squares'), list):
        sys.exit(f"{path}: expected a YAML mapping with 'dimension' and a 'squares' list")
    dimension = data.get('dimension')
    if dimension not in DIMENSION_SUBDIR:
        sys.exit(f"{path}: 'dimension' must be one of {', '.join(DIMENSION_SUBDIR)}")
    squares = []
    for i, entry in enumerate(data['squares'], 1):
        try:
            ax, az = entry['a']
            bx, bz = entry['b']
        except (KeyError, TypeError, ValueError):
            sys.exit(f"{path}: square #{i} must have 'a: [x, z]' and 'b: [x, z]'")
        squares.append((min(ax, bx), min(az, bz), max(ax, bx), max(az, bz)))
    return dimension, squares


def chunk_kept(cx, cz, squares):
    return any(x1 <= cx <= x2 and z1 <= cz <= z2 for x1, z1, x2, z2 in squares)


def find_region_dirs(world, dimension):
    world = Path(world)
    if not world.is_dir():
        sys.exit(f'{world}: not a directory')
    if next(world.glob('*.mca'), None) is not None:
        return [world]  # path is a region directory itself
    if not (world / 'level.dat').exists():
        sys.exit(f'{world}: no level.dat and no .mca files found, not a world?')
    dim_root = world / DIMENSION_SUBDIR[dimension]
    dirs = [dim_root / name for name in ('region', 'entities', 'poi')
            if (dim_root / name).is_dir()]
    if not dirs:
        sys.exit(f'{dim_root}: no region/entities/poi directories found')
    return dirs


def external_mcc(region_path, data, off, cx, cz):
    """Path of the external .mcc file if this chunk's data lives outside the region file."""
    if data[off * SECTOR + 4] & 0x80:
        return region_path.parent / f'c.{cx}.{cz}.mcc'
    return None


def scan_region(path, rx, rz, squares):
    region = anvil.Region.from_file(str(path))
    kept, removed = [], []
    if len(region.data) < 2 * SECTOR:  # empty or truncated header, no chunks
        return region, kept, removed
    for cz in range(32):
        for cx in range(32):
            off, sectors = region.chunk_location(cx, cz)
            if off == 0 and sectors == 0:
                continue
            gx, gz = rx * 32 + cx, rz * 32 + cz
            target = kept if chunk_kept(gx, gz, squares) else removed
            target.append((cx, cz, gx, gz, off))
    return region, kept, removed


def rebuild(region, kept, removed):
    """Return new .mca file contents with only the kept chunks."""
    data = region.data
    loc_header = bytearray(SECTOR)
    ts_header = bytearray(data[SECTOR:2 * SECTOR])
    payload = bytearray()
    for cx, cz, _gx, _gz, off in kept:
        start = off * SECTOR
        length = int.from_bytes(data[start:start + 4], 'big')
        raw = data[start:start + 4 + length]
        i = 4 * (cx + cz * 32)
        loc_header[i:i + 3] = (2 + len(payload) // SECTOR).to_bytes(3, 'big')
        loc_header[i + 3] = max(1, math.ceil(len(raw) / SECTOR))
        raw += bytes(-len(raw) % SECTOR)
        payload += raw
    for cx, cz, _gx, _gz, _off in removed:
        i = 4 * (cx + cz * 32)
        ts_header[i:i + 4] = bytes(4)
    return bytes(loc_header + ts_header + payload)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('world', help='world directory (with level.dat) or a region directory')
    parser.add_argument('-c', '--config', default='config/overworld.yaml', help='squares config (default: config/overworld.yaml)')
    parser.add_argument('--apply', action='store_true', help='actually delete chunks (default: dry run)')
    args = parser.parse_args()

    dimension, squares = load_config(args.config)
    print(f'Loaded {len(squares)} squares from {args.config} (dimension: {dimension})')

    total_kept = total_removed = bytes_saved = files_deleted = files_rewritten = 0
    for region_dir in find_region_dirs(args.world, dimension):
        print(f'\n{region_dir}:')
        for path in sorted(region_dir.glob('*.mca')):
            m = REGION_RE.match(path.name)
            if not m:
                print(f'  {path.name}: unrecognized name, skipped')
                continue
            rx, rz = int(m.group(1)), int(m.group(2))
            region, kept, removed = scan_region(path, rx, rz, squares)
            total_kept += len(kept)
            total_removed += len(removed)
            mcc_files = [p for chunk in removed
                         if (p := external_mcc(path, region.data, chunk[4], chunk[2], chunk[3]))
                         and p.exists()]
            if not removed:
                continue
            if not kept:
                files_deleted += 1
                bytes_saved += path.stat().st_size
                print(f'  {path.name}: delete whole file ({len(removed)} chunks)')
                if args.apply:
                    path.unlink()
            else:
                new_data = rebuild(region, kept, removed)
                files_rewritten += 1
                bytes_saved += len(region.data) - len(new_data)
                print(f'  {path.name}: keep {len(kept)}, remove {len(removed)} chunks')
                if args.apply:
                    path.write_bytes(new_data)
            for p in mcc_files:
                bytes_saved += p.stat().st_size
                print(f'  {p.name}: delete external chunk file')
                if args.apply:
                    p.unlink()

    verb = 'Removed' if args.apply else 'Would remove'
    print(f'\n{verb} {total_removed} chunks (kept {total_kept}), '
          f'{files_deleted} files deleted, {files_rewritten} rewritten, '
          f'{bytes_saved / 1024 / 1024:.1f} MiB saved')
    if not args.apply:
        print('Dry run — nothing was modified. Re-run with --apply to delete chunks.')


if __name__ == '__main__':
    main()
