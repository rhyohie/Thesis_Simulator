"""Image preparation that matches the training pipeline exactly.

Training used: EXIF transpose -> RGB -> PIL bilinear resize to 60x60 -> PIL bilinear
resize to 224x224 -> float32 divided by 255 (no other scaling).
"""
from __future__ import annotations

import base64
import io

import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError

SMALL_SIZE = (60, 60)
MODEL_SIZE = (224, 224)


class ImageDecodeError(ValueError):
    """Raised when the uploaded bytes are not a readable image."""


def _png_b64(image: Image.Image) -> str:
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return base64.b64encode(buffer.getvalue()).decode("ascii")


def prepare(data: bytes) -> tuple[np.ndarray, dict[str, str]]:
    """Return (model input of shape (1, 224, 224, 3) float32, preview images as base64 PNG)."""
    try:
        with Image.open(io.BytesIO(data)) as raw:
            rgb = ImageOps.exif_transpose(raw).convert("RGB")
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
        raise ImageDecodeError("The file is not a readable image.") from exc

    # Same round trip as the training code (numpy uint8 -> PIL) so the pixels are identical.
    base = Image.fromarray(np.asarray(rgb, dtype=np.uint8))
    small = base.resize(SMALL_SIZE, Image.Resampling.BILINEAR)
    model_image = small.resize(MODEL_SIZE, Image.Resampling.BILINEAR)

    x = np.asarray(model_image, dtype=np.uint8).astype(np.float32) / 255.0
    thumbnail = base.copy()
    thumbnail.thumbnail((256, 256))
    previews = {
        "original_png_b64": _png_b64(thumbnail),
        "small_60_png_b64": _png_b64(small),
        "model_224_png_b64": _png_b64(model_image),
    }
    return x[None, ...], previews
