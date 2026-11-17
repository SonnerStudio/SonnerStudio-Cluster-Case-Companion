"""Erzeugt einen abgespeckten Modellordner nur mit den Gewichten eines Pipeline-Rangs.

Verwendung:
  python make_rank_shard.py <voller_modellordner> <zielordner> <start_layer> <end_layer>

Behält: Schichten [start, end), Embeddings, finale Norm, LM-Head (alle Ränge
berechnen den LM-Head nach dem all_gather). Lässt Vision-Gewichte weg.
"""

import json
import re
import shutil
import sys
from pathlib import Path

import mlx.core as mx

src, dst, start, end = Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
dst.mkdir(parents=True, exist_ok=True)

for f in src.iterdir():
    if f.suffix != ".safetensors":
        shutil.copy2(f.resolve(), dst / f.name)

wm = json.loads((src / "model.safetensors.index.json").read_text())["weight_map"]
keep = {}
for k, fname in wm.items():
    if re.search(r"(^|\.)(visual|vision_tower|vision_model)\.", k):
        continue
    m = re.search(r"(?:^|\.)layers\.(\d+)\.", k)
    if m and not (start <= int(m.group(1)) < end):
        continue
    keep.setdefault(fname, []).append(k)

out = {}
for fname, keys in keep.items():
    w = mx.load(str(src / fname))
    for k in keys:
        out[k] = w[k]
mx.save_safetensors(str(dst / "model-rank-shard.safetensors"), out, metadata={"format": "mlx"})
size = sum(v.nbytes for v in out.values()) / 1e9
print(f"{len(out)} Tensoren, {size:.2f} GB -> {dst}")
