import io
import os
from pathlib import Path

import numpy as np
import pytest
from fastapi.testclient import TestClient
from PIL import Image

MODEL_DIR = Path(os.environ.get("MODEL_DIR", Path(__file__).resolve().parent.parent / "model"))
HAS_MODIFIED = (MODEL_DIR / "modified" / "config.json").exists() and (
    MODEL_DIR / "modified" / "best.weights.h5"
).exists()
HAS_BASELINE = (MODEL_DIR / "baseline" / "config.json").exists() and any(
    (MODEL_DIR / "baseline" / name).exists() for name in ("best.weights.h5", "final.weights.h5")
)
pytestmark = pytest.mark.skipif(
    not (HAS_MODIFIED or HAS_BASELINE), reason="no model files in server/model"
)


@pytest.fixture(scope="module")
def client():
    from app.main import app

    with TestClient(app) as c:
        yield c


def _image_bytes(seed=0, fmt="PNG", size=(300, 200)):
    rng = np.random.default_rng(seed)
    arr = rng.integers(0, 255, size=(size[1], size[0], 3), dtype=np.uint8)
    buf = io.BytesIO()
    Image.fromarray(arr).save(buf, format=fmt)
    return buf.getvalue()


def _post(client, model, checkpoint="", seed=0):
    params = {"model": model}
    if checkpoint:
        params["checkpoint"] = checkpoint
    return client.post("/analyze", params=params, files={"file": ("x.png", _image_bytes(seed), "image/png")})


def _check_common(j):
    assert abs(sum(j["prediction"]["probabilities"]) - 1) < 1e-3
    assert len(j["blocks"]) == 5 and [b["shape"] for b in j["blocks"]][-1] == "7×7×512"
    for b in j["blocks"]:
        assert len(b["maps"]) == 16 and all(max(m["v"]) <= 255 and max(m["vs"]) <= 255 for m in b["maps"])
    for cls in j["classify"]["classes"]:
        # all contributions + bias == raw score
        # float32 arithmetic: allow a small relative tolerance (large logits lose absolute precision)
        assert abs(cls["sum_all"] + cls["bias"] - cls["logit"]) <= 1e-3 * max(1.0, abs(cls["logit"]))
        assert len(cls["top"]) == 5
    for key in ("original_png_b64", "small_60_png_b64", "model_224_png_b64"):
        assert len(j["previews"][key]) > 100


def test_info(client):
    info = client.get("/model-info").json()
    assert info["class_names"] == ["Healthy", "Black Pod Rot", "Pod Borer"]
    assert {m["id"] for m in info["models"]} <= {"modified", "baseline"}
    assert client.get("/health").json()["status"] == "ok"


@pytest.mark.skipif(not HAS_MODIFIED, reason="modified model files missing")
@pytest.mark.parametrize("checkpoint", ["best", "final"])
def test_modified(client, checkpoint):
    r = _post(client, "modified", checkpoint)
    assert r.status_code == 200, r.text
    j = r.json()
    _check_common(j)
    assert j["meta"]["model"] == "modified" and j["head"] is None
    assert j["classify"]["features_total"] == 512 and len(j["average"]["all_averages"]) == 512
    for c, cls in enumerate(j["classify"]["classes"]):
        cam = np.array(j["evidence"]["maps"][c]["v"])
        assert abs(cam.mean() + cls["bias"] - cls["logit"]) < 1e-2


@pytest.mark.skipif(not HAS_BASELINE, reason="baseline model files missing")
def test_baseline(client):
    r = _post(client, "baseline")
    assert r.status_code == 200, r.text
    j = r.json()
    _check_common(j)
    assert j["meta"]["model"] == "baseline" and j["average"] is None and j["evidence"] is None
    assert len(j["head"]["stages"]) == 2 and j["head"]["flatten_values"] == 25088
    assert 0 <= j["head"]["stages"][1]["active_fraction"] <= 1
    assert j["classify"]["feature_label"] == "unit"


@pytest.mark.skipif(not HAS_MODIFIED, reason="modified model files missing")
def test_same_image_same_answer(client):
    a = _post(client, "modified", seed=3).json()
    b = _post(client, "modified", seed=3).json()
    assert a["prediction"]["probabilities"] == b["prediction"]["probabilities"]


def test_bad_inputs(client):
    assert client.post("/analyze", files={"file": ("x.txt", b"not an image", "text/plain")}).status_code == 400
    assert client.post("/analyze", files={"file": ("x.png", b"", "image/png")}).status_code == 400
    assert _post(client, "nope").status_code == 400
    assert _post(client, "modified", "nope").status_code == 400


def test_analyze_all_and_ablation(client):
    r = client.post("/analyze-all", files={"file": ("x.png", _image_bytes(), "image/png")})
    assert r.status_code == 200, r.text
    j = r.json()
    assert len(j["previews"]["model_224_png_b64"]) > 100
    ids = [res["meta"]["model"] for res in j["results"]]
    assert ids == [m for m in ("modified", "baseline") if m in ids] and len(ids) >= 1
    for res in j["results"]:
        _check_common({**res, "previews": j["previews"]})
    info = client.get("/model-info").json()
    assert [r["model"] for r in info["ablation"]["rows"]][:2] == ["Baseline", "Baseline"]
    assert client.get("/ablation-figure").status_code == 200
    for m in info["models"]:
        for c in m["checkpoints"]:
            ev = c["evaluation"]
            assert len(ev["f1"]) == 3 and abs(sum(ev["f1"]) / 3 - ev["macro_f1"]) < 2e-3
