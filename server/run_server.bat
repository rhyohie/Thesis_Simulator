@echo off
REM Starts the Python service on http://localhost:8000 (run from the server folder).
call .venv\Scripts\activate
uvicorn app.main:app --host 127.0.0.1 --port 8000
