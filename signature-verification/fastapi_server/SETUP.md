# FastAPI Server Setup Guide

## Prerequisites

1. **Python 3.8+** installed
2. **PostgreSQL** database server running
3. **Database created** named `signature_db`

## Quick Setup

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Database Setup
Create a PostgreSQL database and run the SQL setup:
```bash
# Connect to PostgreSQL as superuser
psql -U postgres

# Create database (if not exists)
CREATE DATABASE signature_db;

# Connect to the database
\c signature_db

# Run the database setup script
\i database_setup.sql
```

### 3. Environment Configuration (Optional)
Set environment variables to override default database settings:

**Windows (PowerShell):**
```powershell
$env:DB_HOST = "localhost"
$env:DB_NAME = "signature_db"
$env:DB_USER = "postgres"
$env:DB_PASSWORD = "your_password"
$env:DB_PORT = "5432"
```

**Windows (Command Prompt):**
```cmd
set DB_HOST=localhost
set DB_NAME=signature_db
set DB_USER=postgres
set DB_PASSWORD=your_password
set DB_PORT=5432
```

### 4. Start the Server

**Option A: Using the batch file**
```cmd
start_server.bat
```

**Option B: Direct Python command**
```bash
python main.py
```

**Option C: Using uvicorn directly**
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## Server URLs

- **API Base URL:** http://localhost:8000
- **Health Check:** http://localhost:8000/health
- **API Documentation:** http://localhost:8000/docs
- **Alternative Docs:** http://localhost:8000/redoc

## API Endpoints

### Health Check
- **GET** `/health` - Check if server and database are connected

### Signatures
- **POST** `/signatures` - Store a new signature
- **GET** `/signatures` - Get list of signatures (with pagination)
- **GET** `/signatures/{id}` - Get a specific signature
- **GET** `/signatures/{id}/analysis` - Get detailed analysis of a signature

### Statistics
- **GET** `/statistics` - Get database statistics

## Common Issues and Solutions

### Issue 1: Database Connection Failed
**Error:** `Database connection failed: connection to server at "localhost" (127.0.0.1), port 5432 failed`

**Solutions:**
1. Make sure PostgreSQL is running
2. Check if the database `signature_db` exists
3. Verify username/password are correct
4. Check if PostgreSQL is listening on port 5432

### Issue 2: Pydantic Deprecation Warnings
**Fixed in this version** - Updated from `.dict()` to `.model_dump()`

### Issue 3: Port Already in Use
**Error:** `Address already in use`

**Solution:** Either stop the existing process or change the port:
```bash
uvicorn main:app --host 0.0.0.0 --port 8001
```

### Issue 4: Module Not Found
**Error:** `ModuleNotFoundError: No module named 'fastapi'`

**Solution:** Install requirements:
```bash
pip install -r requirements.txt
```

## Testing the API

### Using curl:
```bash
# Health check
curl http://localhost:8000/health

# Get statistics
curl http://localhost:8000/statistics
```

### Using Python requests:
```python
import requests

# Health check
response = requests.get("http://localhost:8000/health")
print(response.json())

# Get statistics
response = requests.get("http://localhost:8000/statistics")
print(response.json())
```

## Production Deployment

For production deployment, consider:

1. **Use a proper WSGI server:**
   ```bash
   pip install gunicorn
   gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker
   ```

2. **Set up environment variables properly**
3. **Configure CORS origins** instead of allowing all origins
4. **Use SSL/HTTPS**
5. **Set up proper logging**
6. **Use a reverse proxy** (nginx/Apache)

## Database Schema

The server automatically creates these tables:
- `signatures` - Main signature data with metadata
- `signature_points` - Detailed point data for each stroke
- Various indexes for performance

See `database_setup.sql` for the complete schema.
