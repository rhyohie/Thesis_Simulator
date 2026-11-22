# Cacao Pod Model Simulator — Step 1 (layout preview, runs in Edge)

Step 1 builds the whole screen flow with a **mock engine**. Every image, map and number
on screen is generated demo data, clearly labeled as such, so the real model's behavior is
never imitated. Later steps replace the mock engine with the real trained model.

## Set up (one step at a time)

1. In a terminal, run `flutter doctor`. Flutter and the Edge (web) device should look healthy.
2. In your Flutter projects folder, create the project (the name must be exactly this):

   flutter create thesis_simulator --platforms=web

3. Copy the `lib` and `test` folders from this zip into the new `thesis_simulator` folder,
   replacing the files there. **Do not change `pubspec.yaml`** (step 1 needs no extra packages).
4. In `thesis_simulator`, run:

   flutter analyze
   flutter test
   flutter run -d edge

## What you should see

- A yellow "Layout preview" banner at the top.
- A 7-step bar: Input, Prepare, Blocks, Average, Classify, Where it looked, Result.
- Step 1: three placeholder pod drawings and a "Run the model" button; after the short
  "Running…" wait, the app moves to Prepare, and Next/Back walk through the stages.

If `flutter analyze` or the run shows errors, copy the full message and send it to me.
Warnings and "info" lines about style are expected and can be ignored for now.

## Requirements

Flutter 3.10 or newer (the code uses Dart 3 switch expressions and `ListenableBuilder`).

## Folder map

- `lib/engine/` — `InferenceEngine` interface, trace data, and the mock engine.
- `lib/state/` — one controller holding the current stage and the selections.
- `lib/screens/` — one file per stage plus the home shell.
- `lib/widgets/` — heat-map, bar chart and pod drawing widgets.
- `lib/core/` — class names, stage list, and the plain-language captions.
