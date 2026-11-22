"""Loads the trained models and turns one image into everything the app displays."""
from __future__ import annotations

import copy
import json
import threading
import time
from pathlib import Path

import numpy as np

from .model_info import CLASS_LABELS, MODELS

BLOCK_SHAPES = ["112×112×64", "56×56×128", "28×28×256", "14×14×512", "7×7×512"]
BLOCK_CHANNELS = [64, 128, 256, 512, 512]
SHOWN_CHANNELS = 16
MAX_SIDE = 28

# folder name -> {checkpoint id: weights file}
WEIGHT_FILES = {
    "modified": {"best": "best.weights.h5", "final": "final.weights.h5"},
    "baseline": {"best": "best.weights.h5", "final": "final.weights.h5"},
}


def _reduce(fmap: np.ndarray) -> np.ndarray:
    """Average-pool a 2D map down to at most MAX_SIDE x MAX_SIDE (display only)."""
    h, w = fmap.shape
    if h > MAX_SIDE and h % MAX_SIDE == 0 and w % MAX_SIDE == 0:
        f = h // MAX_SIDE
        fmap = fmap.reshape(h // f, f, w // f, f).mean(axis=(1, 3))
    return fmap


def _u8_map(fmap: np.ndarray, block_max: float) -> dict:
    """Two quantised versions of one map (0-255):
    v  = stretched to this map's own min..max (shows the pattern inside the map)
    vs = scaled by one shared maximum for the whole block (lets maps be compared with each other)
    """
    small = _reduce(fmap)
    lo, hi = float(small.min()), float(small.max())
    if hi - lo > 1e-12:
        q = np.rint(255.0 * (small - lo) / (hi - lo)).astype(int)
    else:
        q = np.zeros(small.shape, dtype=int)
    shared = np.rint(255.0 * np.clip(small / block_max, 0.0, 1.0)).astype(int)
    return {
        "h": int(q.shape[0]),
        "w": int(q.shape[1]),
        "v": q.ravel().tolist(),
        "vs": shared.ravel().tolist(),
    }


def _float_map(fmap: np.ndarray) -> dict:
    return {
        "h": int(fmap.shape[0]),
        "w": int(fmap.shape[1]),
        "v": [round(float(v), 5) for v in fmap.ravel()],
    }


def _bars(values: np.ndarray) -> list[float]:
    """Group a long activation vector into (at most) 256 bars of group means."""
    n = 256 if len(values) % 256 == 0 else len(values)
    return [round(float(v), 4) for v in values.reshape(n, len(values) // n).mean(axis=1)]


class _Loaded:
    def __init__(self, kind: str, tap, weights: np.ndarray, bias: np.ndarray, parameters: int):
        self.kind = kind  # "gap" (modified) or "dense" (baseline)
        self.tap = tap
        self.weights = weights  # (features, 3)
        self.bias = bias  # (3,)
        self.parameters = parameters


class ModelRuntime:
    def __init__(self, model_dir: Path):
        import keras  # imported here so a missing install gives a clear error at startup

        self._lock = threading.Lock()
        self._loaded: dict[tuple[str, str], _Loaded] = {}
        for model_id, files in WEIGHT_FILES.items():
            config_path = model_dir / model_id / "config.json"
            if not config_path.exists():
                print(f"[model] {config_path} not found - model '{model_id}' is unavailable")
                continue
            config = json.loads(config_path.read_text(encoding="utf-8"))["config"]
            for checkpoint, filename in files.items():
                path = model_dir / model_id / filename
                if not path.exists():
                    print(f"[model] {path} not found - '{model_id}/{checkpoint}' is unavailable")
                    continue
                model = keras.models.Model.from_config(copy.deepcopy(config))
                model.load_weights(str(path))
                names = {layer.name for layer in model.layers}
                kind = "gap" if "global_average_pool" in names else "dense"
                outputs = [model.get_layer(f"block{i}_pool").output for i in range(1, 6)]
                if kind == "gap":
                    outputs += [model.get_layer("global_average_pool").output]
                else:
                    outputs += [model.get_layer("fc1").output, model.get_layer("fc2").output]
                outputs += [model.get_layer("class_logits").output, model.output]
                tap = keras.Model(model.input, outputs)
                weights, bias = model.get_layer("class_logits").get_weights()
                self._loaded[(model_id, checkpoint)] = _Loaded(
                    kind, tap, weights, bias, int(model.count_params())
                )
                print(f"[model] loaded '{model_id}/{checkpoint}' ({model.count_params():,} parameters)")
        if not self._loaded:
            raise FileNotFoundError(
                f"No models found in {model_dir}. Expected folders 'modified' and/or 'baseline'. "
                "See the README."
            )

    @property
    def available(self) -> dict[str, list[str]]:
        out: dict[str, list[str]] = {}
        for model_id, checkpoint in self._loaded:
            out.setdefault(model_id, []).append(checkpoint)
        return out

    def analyze(self, x: np.ndarray, model_id: str, checkpoint: str) -> dict:
        loaded = self._loaded[(model_id, checkpoint)]
        started = time.perf_counter()
        with self._lock:
            outputs = [np.asarray(t) for t in loaded.tap(x, training=False)]
        pools = [o[0] for o in outputs[:5]]  # each (H, W, C)
        weights, bias = loaded.weights, loaded.bias
        if loaded.kind == "gap":
            gap, logits, probs = outputs[5][0], outputs[6][0], outputs[7][0]
            features = gap
        else:
            fc1, fc2, logits, probs = outputs[5][0], outputs[6][0], outputs[7][0], outputs[8][0]
            features = fc2

        blocks = []
        for i, fmap in enumerate(pools):
            # Show the maps with the most visible pattern (largest spread of values). Showing the
            # "most active" maps instead picks maps that are bright almost everywhere, which draw
            # as one flat yellow block after per-map colour scaling.
            spread = fmap.std(axis=(0, 1))
            order = np.argsort(-spread)[:SHOWN_CHANNELS]
            block_max = float(np.percentile(fmap, 99.5))
            if block_max <= 1e-12:
                block_max = 1.0
            blocks.append(
                {
                    "index": i + 1,
                    "shape": BLOCK_SHAPES[i],
                    "channels": BLOCK_CHANNELS[i],
                    "shown_channels": [int(c) for c in order],
                    "maps": [_u8_map(fmap[:, :, int(c)], block_max) for c in order],
                }
            )

        classes = []
        for c, name in enumerate(CLASS_LABELS):
            products = weights[:, c] * features
            top = np.argsort(-np.abs(products))[:5]
            classes.append(
                {
                    "name": name,
                    "logit": round(float(logits[c]), 5),
                    "bias": round(float(bias[c]), 5),
                    "sum_all": round(float(products.sum()), 5),
                    "top": [
                        {
                            "feature": int(k),
                            "weight": round(float(weights[k, c]), 5),
                            "average": round(float(features[k]), 5),
                            "product": round(float(products[k]), 5),
                        }
                        for k in top
                    ],
                }
            )

        average = None
        evidence = None
        head = None
        if loaded.kind == "gap":
            block5 = pools[4]  # (7, 7, 512)
            shown5 = [int(c) for c in np.argsort(-block5.mean(axis=(0, 1)))[:SHOWN_CHANNELS]]
            average = {
                "channels": shown5,
                "maps": [_float_map(block5[:, :, c]) for c in shown5],
                "channel_averages": [round(float(gap[c]), 5) for c in shown5],
                "all_averages": [round(float(v), 5) for v in gap],
            }
            evidence = {
                "maps": [
                    _float_map(np.einsum("hwk,k->hw", block5, weights[:, c]))
                    for c in range(len(CLASS_LABELS))
                ]
            }
        else:
            head = {
                "flatten_values": int(pools[4].size),
                "stages": [
                    {
                        "name": "Dense layer 1 (ReLU)",
                        "units": int(len(fc1)),
                        "active_fraction": round(float((fc1 > 0).mean()), 4),
                        "bars": _bars(fc1),
                    },
                    {
                        "name": "Dense layer 2 (ReLU)",
                        "units": int(len(fc2)),
                        "active_fraction": round(float((fc2 > 0).mean()), 4),
                        "bars": _bars(fc2),
                    },
                ],
            }

        best = int(np.argmax(probs))
        model_entry = next(m for m in MODELS if m["id"] == model_id)
        cp_entry = next(c for c in model_entry["checkpoints"] if c["id"] == checkpoint)
        return {
            "meta": {
                "model": model_id,
                "model_label": model_entry["label"],
                "checkpoint": checkpoint,
                "checkpoint_label": cp_entry["label"],
                "elapsed_ms": int((time.perf_counter() - started) * 1000),
                "parameters": loaded.parameters,
            },
            "class_names": CLASS_LABELS,
            "prediction": {
                "index": best,
                "label": CLASS_LABELS[best],
                "probability": round(float(probs[best]), 5),
                "probabilities": [round(float(p), 5) for p in probs],
                "logits": [round(float(v), 5) for v in logits],
            },
            "blocks": blocks,
            "classify": {
                "features_total": int(len(features)),
                "feature_label": "feature" if loaded.kind == "gap" else "unit",
                "classes": classes,
            },
            "average": average,
            "evidence": evidence,
            "head": head,
        }
