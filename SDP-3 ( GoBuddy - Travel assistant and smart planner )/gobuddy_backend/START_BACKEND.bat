@echo off
REM Backend startup script for GoBuddy

echo Starting GoBuddy Backend Server...
echo.

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Start the backend on port 5000
echo Starting FastAPI server on http://localhost:5000
python app.py

pause
