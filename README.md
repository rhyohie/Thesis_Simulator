# Cacao Pod Model Simulator — Python service + Flutter web app

A working tool: upload a cacao pod photo, press **Analyze photo**, and get the prediction,
the probability of each class and a class-level results table from the **real trained BN+GAP
model**. You can switch between the **modified BN+GAP model** and the **baseline VGG**. An
optional panel shows how the chosen model processed the photo (the steps differ: only the modified
model has the averaging step and the "where it looked" map).

Layout: `server/` is the Python service that runs the model. `thesis_simulator/` is the Flutter
app. The two communicate over HTTP (default `http://localhost:8000`).

## Prerequisites

- Git
- Git LFS
- Python 3.10–3.12
- Flutter SDK

After cloning, Git LFS downloads both model weights automatically. Do not copy or rename weight
files; the repository already contains them in the correct folders:

- `server/model/modified/best.weights.h5`
- `server/model/baseline/final.weights.h5`

The virtual environment, Flutter build output, `.dart_tool/`, and caches are not stored in Git.
Every user creates these locally.

## Part 1 — Clone and start the Python service

1. Clone the repository:

       git clone https://github.com/rhyohie/Thesis_Simulator.git
       cd Thesis_Simulator
       git lfs pull

   If Git LFS is not installed, run `git lfs install` before cloning or pulling.

2. Create and activate a local virtual environment:

       cd server
       python -m venv .venv
       .venv\Scripts\activate
       python -m pip install --upgrade pip
       python -m pip install -r requirements.txt

3. (Optional) run the tests:

       pytest

4. Start the service:

       uvicorn app.main:app --host 127.0.0.1 --port 8000

   On Windows, you can also double-click `server\run_server.bat` after the virtual environment
   has been created.

5. Open http://localhost:8000/health in a browser. It should show `{"status":"ok",...}`.

Leave this terminal open while using the app.

## Part 2 — Start the Flutter app

1. Open a second terminal in the repository root:

       cd thesis_simulator
       flutter pub get
       flutter analyze
       flutter test
       flutter run -d edge

2. The existing `lib/` and `test/` folders are already in the repository. Do not delete or copy
   them.

3. In the app, the chip at the top should say **Server connected**. Choose a photo (Upload) and
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
