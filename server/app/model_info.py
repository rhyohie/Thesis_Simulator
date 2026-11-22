"""Recorded results shown in the app. Numbers come from the training runs' saved files."""
from __future__ import annotations

CLASS_LABELS = ["Healthy", "Black Pod Rot", "Pod Borer"]

_INPUT = "Photo -> 60x60 -> 224x224 (bilinear), pixel values divided by 255"

MODELS = [
    {
        "id": "modified",
        "label": "Modified: BN+GAP",
        "description": (
            "VGG-style layout with batch normalization after every convolution and a global "
            "average pooling head instead of the two 4096-unit layers."
        ),
        "parameters": 11780163,
        "input_description": _INPUT,
        "default_checkpoint": "best",
        "checkpoints": [
            {
                "id": "best",
                "label": "Selected checkpoint (epoch 99)",
                "epoch": 99,
                "selection_rule": "Best validation macro F1 over 100 epochs",
                "evaluation": {
                    "on": "validation",
                    "images": 877,
                    "accuracy": 0.9293,
                    "macro_f1": 0.7699,
                    "balanced_accuracy": 0.7245,
                    "precision": [0.9418, 0.8895, 0.7778],
                    "recall": [0.9671, 0.8564, 0.35],
                    "f1": [0.9543, 0.8726, 0.4828],
                    "support": [669, 188, 20],
                    "mean_max_probability": 0.9802,
                },
            },
            {
                "id": "final",
                "label": "Final checkpoint (epoch 100)",
                "epoch": 100,
                "selection_rule": "Last epoch of training",
                "evaluation": {
                    "on": "validation",
                    "images": 877,
                    "accuracy": 0.8518,
                    "macro_f1": 0.5208,
                    "balanced_accuracy": 0.4959,
                    "precision": [0.8621, 0.8739, 0.0],
                    "recall": [0.9716, 0.5160, 0.0],
                    "f1": [0.9136, 0.6488, 0.0],
                    "support": [669, 188, 20],
                    "mean_max_probability": 0.9661,
                },
            },
        ],
    },
    {
        "id": "baseline",
        "label": "Baseline: plain VGG",
        "description": (
            "Reconstruction of the baseline study's Table 4 VGG: 11 convolutions, two 4096-unit "
            "dense layers, no batch normalization. Trained with the baseline's settings "
            "(learning rate 0.1), training diverged and the model ended up answering Healthy for "
            "almost every image."
        ),
        "parameters": 131322947,
        "input_description": _INPUT,
        "default_checkpoint": "final",
        "checkpoints": [
            {
                "id": "best",
                "label": "Selected checkpoint (epoch 3)",
                "epoch": 3,
                "selection_rule": (
                    "Best validation macro F1 in the groupmate's baseline trial. It was reached at "
                    "epoch 3 of 100, while training was still diverging (raw scores in the billions)"
                ),
                "evaluation": {
                    "on": "validation",
                    "images": 877,
                    "accuracy": 0.5758,
                    "macro_f1": 0.3330,
                    "balanced_accuracy": 0.3485,
                    "precision": [0.7744, 0.2353, 0.0],
                    "recall": [0.6413, 0.4043, 0.0],
                    "f1": [0.7016, 0.2975, 0.0],
                    "support": [669, 188, 20],
                    "mean_max_probability": 1.0,
                },
            },
            {
                "id": "final",
                "label": "Final epoch (epoch 100)",
                "epoch": 100,
                "selection_rule": "Last epoch of the baseline notebook run (the baseline's primary result)",
                "evaluation": {
                    "on": "validation",
                    "images": 877,
                    "accuracy": 0.7628,
                    "macro_f1": 0.2885,
                    "balanced_accuracy": 0.3333,
                    "precision": [0.7628, 0.0, 0.0],
                    "recall": [1.0, 0.0, 0.0],
                    "f1": [0.8655, 0.0, 0.0],
                    "support": [669, 188, 20],
                    "mean_max_probability": None,
                },
                "also_evaluated": {
                    "on": "test",
                    "images": 441,
                    "accuracy": 0.7596,
                    "macro_f1": 0.2878,
                    "balanced_accuracy": 0.3333,
                    "precision": [0.7596, 0.0, 0.0],
                    "recall": [1.0, 0.0, 0.0],
                    "f1": [0.8634, 0.0, 0.0],
                    "support": [335, 95, 11],
                    "mean_max_probability": None,
                },
            },
        ],
    },
]

# "Why BN+GAP?" panel: preliminary validation runs (thesis Appendix B, Table B1), same 877 images.
ABLATION = {
    "title": "Why BN+GAP instead of BN-only or GAP-only?",
    "source": (
        "Preliminary validation runs from the thesis (Appendix B). All four models: Adamax 0.1, "
        "batch 64, 100 epochs, seed 42, the same 877 validation images (669 Healthy, 188 Black Pod "
        "Rot, 20 Pod Borer). The selected checkpoint is the epoch with the best validation macro F1."
    ),
    "rows": [
        {"model": "Baseline", "checkpoint": "Selected", "epoch": 3, "accuracy": 0.5758, "macro_f1": 0.3330, "pod_borer_found": 0, "loss": 1.1046e8},
        {"model": "Baseline", "checkpoint": "Final", "epoch": 100, "accuracy": 0.7617, "macro_f1": 0.2917, "pod_borer_found": 0, "loss": 7.854e4},
        {"model": "BN-only", "checkpoint": "Selected", "epoch": 22, "accuracy": 0.6534, "macro_f1": 0.3696, "pod_borer_found": 2, "loss": 3.9595},
        {"model": "BN-only", "checkpoint": "Final", "epoch": 100, "accuracy": 0.7628, "macro_f1": 0.2885, "pod_borer_found": 0, "loss": 0.6244},
        {"model": "GAP-only", "checkpoint": "Selected", "epoch": 55, "accuracy": 0.7628, "macro_f1": 0.2885, "pod_borer_found": 0, "loss": 0.6240},
        {"model": "GAP-only", "checkpoint": "Final", "epoch": 100, "accuracy": 0.7628, "macro_f1": 0.2885, "pod_borer_found": 0, "loss": 1.0083},
        {"model": "BN+GAP", "checkpoint": "Selected", "epoch": 99, "accuracy": 0.9293, "macro_f1": 0.7699, "pod_borer_found": 7, "loss": 0.4840},
        {"model": "BN+GAP", "checkpoint": "Final", "epoch": 100, "accuracy": 0.8518, "macro_f1": 0.5208, "pod_borer_found": 0, "loss": 0.8258},
    ],
    "pod_borer_total": 20,
    "takeaways": [
        "BN alone: training stayed stable enough to move past the baseline's collapse, but it remained weak. Best macro F1 was 0.37 with 2 of 20 Pod Borer found, and by the last epoch it answered Healthy for every image.",
        "GAP alone: it stayed at answering Healthy (macro F1 0.2885 at its selected and final epochs), finding 0 of 20 Pod Borer.",
        "BN+GAP together: macro F1 reached 0.77 and 7 of 20 Pod Borer were found at the selected epoch (accuracy 92.9%). In these runs neither change alone was enough.",
    ],
    "caveats": [
        "Preliminary runs, one seed each, and only 20 Pod Borer validation images.",
        "The selected epoch is the best of 100, chosen on the same validation images it is scored on, so it is optimistic. BN+GAP's final epoch fell to macro F1 0.52 with 0 of 20 Pod Borer.",
        "The Baseline rows are the thesis's preliminary baseline run. The baseline model in this app comes from a separate re-run with the same settings (validation accuracy 76.28%, macro F1 0.2885).",
        "BN-only and GAP-only are shown as recorded results only; they are not loaded in this app.",
    ],
}

LIMITS = [
    "This is a research demonstration, not a disease diagnosis.",
    "The modified model's numbers are on validation images only; no test-set evaluation has been done for it. Both models are shown on the same 877 validation images so they can be compared.",
    "The modified model's checkpoint was selected on the same validation images, so its numbers are optimistic. The final epoch scored clearly lower, and results moved a lot between neighbouring epochs.",
    "Pod Borer is found only 7 times out of 20 validation images at the selected epoch (0 of 20 at the final epoch).",
    "The modified model's probabilities are probably overconfident: on validation images the average top probability was about 0.98 while accuracy was 92.9%.",
    "A model has no \"not a cacao pod\" option: every image gets one of the three answers, even a photo of something else. In a quick test on pure random noise the modified model's selected checkpoint answered Pod Borer with 99.996% probability.",
    "One training run and one random seed per model.",
]

# Shown only when the baseline's epoch-3 checkpoint (from the groupmate's trial) is loaded.
LIMIT_BASELINE_BEST = (
    "The baseline's epoch-3 checkpoint comes from a stage when training was still diverging: its raw "
    "scores reach the billions and its probabilities are always 0 or 1. It is not the baseline's final "
    "state."
)
