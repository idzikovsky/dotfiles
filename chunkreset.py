#!/usr/bin/env python
"""Reset the chunks inside the squares defined in a coords.yaml in a Minecraft world.

Inverse of chunkcleaner.py: chunks inside the squares are deleted so Minecraft
regenerates them on the next visit; all other chunks are kept untouched.

The config is a YAML mapping with the target dimension and a list of
rectangles given by two opposite corners in chunk coordinates (inclusive):

    dimension: overworld
    squares:
      - descr: "woodland mansion"
        a: [ 515, 411 ]
        b: [ 519, 416 ]

By default this is a dry run; pass --apply to actually modify the world.
Region files are rewritten by copying the raw bytes of kept chunks, so chunk
data survives untouched for any Minecraft version; files whose chunks are all
inside the squares are deleted entirely.
"""
import argparse

from chunkcleaner import (
    REGION_RE,
    external_mcc,
    find_region_dirs,
    load_config,
    rebuild,
    scan_region,
)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('world', help='world directory (with level.dat) or a region directory')
    parser.add_argument('-c', '--config', required=True, help='squares config with the chunks to reset')
    parser.add_argument('--apply', action='store_true', help='actually delete chunks (default: dry run)')
    args = parser.parse_args()

    dimension, squares = load_config(args.config)
    print(f'Loaded {len(squares)} squares from {args.config} (dimension: {dimension})')

    total_kept = total_reset = bytes_saved = files_deleted = files_rewritten = 0
    for region_dir in find_region_dirs(args.world, dimension):
        print(f'\n{region_dir}:')
        for path in sorted(region_dir.glob('*.mca')):
            m = REGION_RE.match(path.name)
            if not m:
                print(f'  {path.name}: unrecognized name, skipped')
                continue
            rx, rz = int(m.group(1)), int(m.group(2))
            region, inside, outside = scan_region(path, rx, rz, squares)
            kept, removed = outside, inside  # inverse of chunkcleaner
            total_kept += len(kept)
            total_reset += len(removed)
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
                print(f'  {path.name}: keep {len(kept)}, reset {len(removed)} chunks')
                if args.apply:
                    path.write_bytes(new_data)
            for p in mcc_files:
                bytes_saved += p.stat().st_size
                print(f'  {p.name}: delete external chunk file')
                if args.apply:
                    p.unlink()

    verb = 'Reset' if args.apply else 'Would reset'
    print(f'\n{verb} {total_reset} chunks (kept {total_kept}), '
          f'{files_deleted} files deleted, {files_rewritten} rewritten, '
          f'{bytes_saved / 1024 / 1024:.1f} MiB saved')
    if not args.apply:
        print('Dry run — nothing was modified. Re-run with --apply to reset chunks.')


if __name__ == '__main__':
    main()
