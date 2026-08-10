@echo off
echo Starting Signature Collection API Server...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.8+ and try again
    pause
    exit /b 1
)

REM Navigate to server directory
cd /d "%~dp0fastapi_server"

REM Check if requirements are installed
pip show fastapi >nul 2>&1
if errorlevel 1 (
    echo Installing Python dependencies...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo Error: Failed to install dependencies
        pause
        exit /b 1
    )
)

REM Set default environment variables if not set
if not defined DB_HOST set DB_HOST=localhost
if not defined DB_NAME set DB_NAME=signature_db
if not defined DB_USER set DB_USER=postgres
if not defined DB_PASSWORD set DB_PASSWORD=password
if not defined DB_PORT set DB_PORT=5432

echo.
echo Configuration:
echo - Database Host: %DB_HOST%
echo - Database Name: %DB_NAME%
echo - Database User: %DB_USER%
echo - Database Port: %DB_PORT%
echo.

echo Starting server on http://localhost:8000
echo API Documentation: http://localhost:8000/docs
echo Health Check: http://localhost:8000/health
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the server
python main.py

pause
