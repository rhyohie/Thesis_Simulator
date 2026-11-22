from __future__ import annotations

import os

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from starlette.concurrency import run_in_threadpool

from .model_info import ABLATION, CLASS_LABELS, LIMIT_BASELINE_BEST, LIMITS, MODELS
from .preprocess import ImageDecodeError, prepare
from .runtime import ModelRuntime

BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_DIR = Path(os.environ.get("MODEL_DIR", BASE_DIR / "model"))
ASSETS_DIR = BASE_DIR / "assets"
MAX_BYTES = 15 * 1024 * 1024


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.runtime = ModelRuntime(MODEL_DIR)
    yield


app = FastAPI(title="Cacao Pod Model Simulator API", version="3.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # local development; restrict this before any public hosting
    allow_methods=["*"],
    allow_headers=["*"],
)


def _default_checkpoint(model_id: str, available: dict[str, list[str]]) -> str:
    preferred = next(m for m in MODELS if m["id"] == model_id)["default_checkpoint"]
    return preferred if preferred in available[model_id] else available[model_id][0]


async def _read_and_prepare(file: UploadFile):
    data = await file.read(MAX_BYTES + 1)
    if not data:
        raise HTTPException(400, "The uploaded file is empty.")
    if len(data) > MAX_BYTES:
        raise HTTPException(413, "The image is larger than 15 MB.")
    try:
        return await run_in_threadpool(prepare, data)
    except ImageDecodeError as exc:
        raise HTTPException(400, str(exc)) from exc


@app.get("/health")
def health():
    return {"status": "ok", "models": app.state.runtime.available}


@app.get("/model-info")
def model_info():
    available = app.state.runtime.available
    models = []
    for m in MODELS:
        if m["id"] not in available:
            continue
        entry = dict(m)
        entry["checkpoints"] = [c for c in m["checkpoints"] if c["id"] in available[m["id"]]]
        models.append(entry)
    limits = list(LIMITS)
    if "best" in available.get("baseline", []):
        limits.insert(-1, LIMIT_BASELINE_BEST)
    return {"class_names": CLASS_LABELS, "models": models, "limits": limits, "ablation": ABLATION}


@app.get("/ablation-figure")
def ablation_figure():
    path = ASSETS_DIR / "ablation_histories.png"
    if not path.exists():
        raise HTTPException(404, "ablation_histories.png is missing from server/assets.")
    return FileResponse(path, media_type="image/png")


@app.post("/analyze")
async def analyze(file: UploadFile = File(...), model: str = "modified", checkpoint: str = ""):
    """One model, one checkpoint (kept for testing)."""
    runtime: ModelRuntime = app.state.runtime
    available = runtime.available
    if model not in available:
        raise HTTPException(400, f"Unknown or unavailable model '{model}'. Available: {', '.join(available)}")
    if not checkpoint:
        checkpoint = _default_checkpoint(model, available)
    if checkpoint not in available[model]:
        raise HTTPException(
            400, f"Unknown checkpoint '{checkpoint}' for '{model}'. Available: {', '.join(available[model])}"
        )
    x, previews = await _read_and_prepare(file)
    result = await run_in_threadpool(runtime.analyze, x, model, checkpoint)
    result["previews"] = previews
    return result


@app.post("/analyze-all")
async def analyze_all(file: UploadFile = File(...)):
    """Runs every loaded model (default checkpoint each) on the same photo."""
    runtime: ModelRuntime = app.state.runtime
    available = runtime.available
    x, previews = await _read_and_prepare(file)
    results = []
    for entry in MODELS:
        model_id = entry["id"]
        if model_id not in available:
            continue
        checkpoint = _default_checkpoint(model_id, available)
        results.append(await run_in_threadpool(runtime.analyze, x, model_id, checkpoint))
    return {"previews": previews, "results": results}
