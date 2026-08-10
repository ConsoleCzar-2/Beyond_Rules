@echo off
echo Starting Signature Collection FastAPI Server...
echo.
echo Make sure PostgreSQL is running and the database 'signature_db' exists.
echo Default database configuration:
echo   Host: localhost
echo   Database: signature_db
echo   User: postgres
echo   Password: password
echo   Port: 5432
echo.
echo You can override these with environment variables:
echo   DB_HOST, DB_NAME, DB_USER, DB_PASSWORD, DB_PORT
echo.

cd /d "%~dp0"
python main.py

pause
