#!/usr/bin/env python
"""Print a coords config with all coordinates multiplied by 16 (chunk -> block coords)."""
import argparse
import sys

import yaml


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('config', nargs='?', default='config/overworld.yaml',
                        help='squares config (default: config/overworld.yaml)')
    args = parser.parse_args()

    with open(args.config) as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict) or not isinstance(data.get('squares'), list):
        sys.exit(f"{args.config}: expected a YAML mapping with 'dimension' and a 'squares' list")

    for square in data['squares']:
        for corner in ('a', 'b'):
            if corner in square:
                square[corner] = [v * 16 for v in square[corner]]

    yaml.dump(data, sys.stdout, default_flow_style=None, sort_keys=False)


if __name__ == '__main__':
    main()
