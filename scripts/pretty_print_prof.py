#!/usr/bin/env python3
"""
Pretty-print Cangjie runtime CPU profile (.prof) files.

The .prof format is Chrome DevTools CPU profile (JSON with nodes, samples, timeDeltas).
Usage:
  python3 scripts/pretty_print_prof.py cpu_iter_0.prof [cpu_iter_1.prof ...]
  python3 scripts/pretty_print_prof.py --all   # all *.prof in current dir
"""

import json
import sys
from pathlib import Path
from typing import Dict, Tuple


def load_prof(path: Path) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def node_label(node: dict) -> str:
    cf = node.get("callFrame") or {}
    name = cf.get("functionName") or "(unknown)"
    url = (cf.get("url") or "").strip()
    line = cf.get("lineNumber", 0)
    if url:
        # show file name and line
        short = Path(url).name if url else ""
        return f"{name} @ {short}:{line}" if short else name
    return name


def analyze(prof: dict) -> Tuple[Dict[int, int], int, int]:
    """Returns (node_id -> self_time_us), total_time_us, sample_count."""
    nodes = {n["id"]: n for n in prof.get("nodes", [])}
    samples = prof.get("samples", [])
    time_deltas = prof.get("timeDeltas", [])

    # Self time: time attributed to the node at the top of the stack at each sample.
    # timeDeltas[i] is the time (µs) until the next sample; attribute it to samples[i].
    self_time = {}
    total_us = 0
    for i, node_id in enumerate(samples):
        delta = time_deltas[i] if i < len(time_deltas) else 0
        self_time[node_id] = self_time.get(node_id, 0) + delta
        total_us += delta

    return self_time, total_us, len(samples)


def print_report(path: Path, prof: dict, self_time: dict, total_us: int, sample_count: int) -> None:
    nodes = {n["id"]: n for n in prof.get("nodes", [])}
    # Sort by self time descending, skip zero and root-like
    entries = [
        (nid, t) for nid, t in self_time.items()
        if t > 0 and nid in nodes and nodes[nid].get("callFrame", {}).get("functionName") not in ("(root)", "(program)", "(idle)")
    ]
    entries.sort(key=lambda x: -x[1])

    duration_ms = total_us / 1000.0
    managed = prof.get("managedTime", 0)
    unknown = prof.get("unknownTime", 0)

    print(f"\n{'='*70}")
    print(f"  {path.name}")
    print(f"{'='*70}")
    print(f"  Duration (from samples): {duration_ms:.2f} ms  ({total_us} µs)")
    print(f"  managedTime: {managed} µs   unknownTime: {unknown} µs")
    print(f"  Samples: {sample_count}")
    print(f"{'='*70}")
    print(f"  Top functions by self time (µs):")
    print(f"  {'Self (µs)':>12}  {'%':>6}  Function")
    print(f"  {'-'*12}  {'-'*6}  {'-'*50}")

    for nid, t in entries[:25]:
        pct = (100.0 * t / total_us) if total_us else 0
        label = node_label(nodes[nid])
        if len(label) > 52:
            label = label[:49] + "..."
        print(f"  {t:>12}  {pct:>5.1f}%  {label}")
    print()


def main() -> None:
    if not sys.argv[1:]:
        print("Usage: pretty_print_prof.py <file.prof> [file2.prof ...]")
        print("       pretty_print_prof.py --all")
        sys.exit(1)

    paths = []
    if sys.argv[1] == "--all":
        paths = sorted(Path(".").glob("*.prof"))
        if not paths:
            print("No .prof files in current directory.")
            sys.exit(1)
    else:
        for a in sys.argv[1:]:
            p = Path(a)
            if not p.exists():
                print(f"File not found: {p}", file=sys.stderr)
                sys.exit(1)
            paths.append(p)

    for path in paths:
        try:
            prof = load_prof(path)
        except Exception as e:
            print(f"Error reading {path}: {e}", file=sys.stderr)
            continue
        self_time, total_us, sample_count = analyze(prof)
        print_report(path, prof, self_time, total_us, sample_count)


if __name__ == "__main__":
    main()
