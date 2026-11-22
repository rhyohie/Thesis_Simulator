# Cacao Pod Model Simulator — Python service + Flutter web app

A working tool: upload a cacao pod photo, press **Analyze photo**, and get the prediction,
the probability of each class and a class-level results table from the **real trained BN+GAP
model**. You can switch between the **modified BN+GAP model** and the **baseline VGG**. An
optional panel shows how the chosen model processed the photo (the steps differ: only the modified
model has the averaging step and the "where it looked" map).

Layout: `server/` is the Python service that runs the model. `flutter/` holds the `lib` and
`test` folders for the Flutter app. The two talk over HTTP (default `http://localhost:8000`).

## Part 1 — Python service (do this first)

1. Check your Python version: `python --version`. TensorFlow normally needs Python 3.10–3.12.
2. In a terminal, go into the `server` folder and create an environment:

       python -m venv .venv
       .venv\Scripts\activate
       pip install -r requirements.txt

3. Put the weights in the model folders. Each folder already has its `config.json`.
   **One checkpoint per model is enough:**

       server\model\modified\best.weights.h5     <- model_weights.h5 (BN+GAP, selected epoch 99)
       server\model\baseline\final.weights.h5    <- final.weights.h5 from YOUR baseline notebook
                                                     (final epoch 100, the thesis baseline)

   Copy the files and **rename** them as shown. Your baseline's `final.weights.h5` is 1.58 GB
   (it also stores the optimizer state); the service loads it as it is. If you prefer a 525 MB
   file, `make_slim_baseline.ipynb` converts it on Kaggle (optional).

   Optional extras, shown in the app as additional checkpoints only if the files exist:
   `modified\final.weights.h5` (BN+GAP final epoch 100) and `baseline\best.weights.h5` (the
   groupmate's baseline trial, selected at epoch 3 while training was diverging).

4. (Optional) run the tests, which use the real weights: `pytest`
5. Start the service: `uvicorn app.main:app --port 8000` (or double-click `run_server.bat`).
6. Open http://localhost:8000/health in a browser. It should show `{"status":"ok",...}`.

Leave this window open while you use the app.

## Part 2 — Flutter app

1. In your `thesis_simulator` project, **delete the old `lib` and `test` folders**, then copy
   in the new ones from `flutter/` in this zip.
2. In the project folder, add the two packages (do not edit pubspec.yaml by hand):

       flutter pub add http image_picker

3. Run `flutter analyze`, then `flutter test`, then `flutter run -d edge`.
4. In the app, the chip at the top should say **Server connected**. Choose a photo (Upload) and
   press **Analyze photo**. **Both models answer the same photo at once**, side by side, with a
   line saying whether they agree. Each card shows the prediction, the probability of every class,
   and the recorded **F1 score** of each class (the small "?" next to the F1 header explains it).
   The **"?" button on the modified model's card** opens the comparison of the baseline, BN-only,
   GAP-only and BN+GAP (learning-history figure plus table). Open "How the models processed this
   photo" for the details; use the chips to switch between the two models' steps.

## Notes

- The learning-history figure in the "?" panel is served by the service from
  `server/assets/ablation_histories.png`; BN-only and GAP-only appear there as recorded results only
  (their weights are not loaded in the app).
- Both models always answer with one of three classes, even for photos that are not cacao pods.
  The modified model's probabilities are often overconfident and Pod Borer is its weakest class.
  The baseline answers Healthy for everything. The app says so; see **About the model** for the
  recorded results (validation images for the modified model, test images for the baseline: do not
  compare them directly).
- Camera: on a computer the Camera button opens a file chooser; on a phone it uses the camera.
- The service allows any web origin (needed for local development). Restrict it before any
  public hosting.
- Server address can be changed with the gear icon (for example if you use another port).
