# Quick Start Guide - Advanced Signature Capture System

## 🚀 Quick Setup (5 Minutes)

### 1. Start the Backend Server

**Option A: Using the Batch Script (Windows)**
```bash
# Double-click or run in command prompt
start_server.bat
```

**Option B: Manual Setup**
```bash
cd fastapi_server
pip install -r requirements.txt
python main.py
```

**Option C: Using Docker**
```bash
cd fastapi_server
docker-compose up -d
```

### 2. Set Up PostgreSQL Database

**Install PostgreSQL** (if not already installed):
- Download from: https://www.postgresql.org/download/
- Or use Docker: `docker run --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres`

**Create Database:**
```sql
-- Connect to PostgreSQL as superuser
CREATE DATABASE signature_db;

-- Run the setup script
\i fastapi_server/database_setup.sql
```

### 3. Run the Flutter App

```bash
flutter pub get
flutter run
```

**Choose your platform:**
- `flutter run -d windows` (Windows desktop)
- `flutter run -d chrome` (Web browser)
- `flutter run` (Mobile device/emulator)

### 4. Test the System

1. **Check server status**: Visit http://localhost:8000/health
2. **View API docs**: Visit http://localhost:8000/docs
3. **Draw a signature** in the Flutter app
4. **Verify data storage**: Check the database or API responses

## 📱 Using the App

### Drawing Signatures
1. Open the app
2. Check the server connection status (green = connected)
3. Draw your signature in the designated area
4. Click "Save Signature" to upload to server
5. View signature statistics and recent signatures

### Captured Data
Each signature captures:
- **Stroke patterns**: Individual pen strokes with timing
- **Pressure data**: Pressure values throughout the signature
- **Velocity tracking**: Speed of drawing at each point
- **Timing information**: Precise timestamps for each point
- **Spatial data**: X/Y coordinates and bounding boxes

## 🔧 Configuration

### Server Configuration
Edit these environment variables or update the code:

```bash
# Database settings
DB_HOST=localhost
DB_NAME=signature_db
DB_USER=postgres
DB_PASSWORD=password
DB_PORT=5432
```

### Flutter App Configuration
Update the server URL in `lib/services/signature_api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:8000';
```

For mobile devices, use your computer's IP address:
```dart
static const String baseUrl = 'http://192.168.1.100:8000';
```

## 📊 Viewing and Exporting Data

### Via Web Interface
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **Get Signatures**: http://localhost:8000/signatures
- **Statistics**: http://localhost:8000/statistics

### Via Database
```sql
-- View all signatures
SELECT * FROM signatures ORDER BY created_at DESC;

-- Get signature statistics
SELECT * FROM get_signature_stats();

-- Analyze signature complexity
SELECT 
    CASE 
        WHEN total_strokes <= 5 THEN 'Simple'
        WHEN total_strokes <= 10 THEN 'Moderate'
        ELSE 'Complex'
    END as complexity,
    COUNT(*) as count
FROM signatures 
GROUP BY 1;
```

### ML Data Export
```bash
cd fastapi_server

# Export to CSV for analysis
python ml_export.py --format csv --output my_signatures

# Export to JSON for backup
python ml_export.py --format json --output my_signatures

# Export to NumPy for ML training
python ml_export.py --format numpy --output my_signatures

# Generate dataset report
python ml_export.py --report
```

## 🎯 What Makes This Special

### Advanced Signature Capture
- **Real-time pressure detection**: Captures drawing pressure
- **Velocity tracking**: Records drawing speed and acceleration
- **Stroke analysis**: Individual stroke patterns and timing
- **Smooth rendering**: Bezier curves for natural line appearance

### ML-Ready Data
- **Temporal features**: Timing patterns and stroke duration
- **Spatial features**: Coordinate sequences and geometric properties
- **Dynamic features**: Velocity, acceleration, and pressure profiles
- **Statistical features**: Aggregated metrics for quick analysis

### Production Ready
- **Robust API**: FastAPI with automatic documentation
- **Scalable database**: PostgreSQL with optimized schema
- **Cross-platform**: Works on mobile, desktop, and web
- **Docker support**: Easy deployment and scaling

## 🔧 Troubleshooting

### Common Issues

**1. Server Connection Failed**
- Check if the server is running on port 8000
- Verify firewall settings
- For mobile: Use computer's IP address instead of localhost

**2. Database Connection Error**
- Ensure PostgreSQL is running
- Check database credentials
- Verify database exists and is accessible

**3. Flutter Build Issues**
- Run `flutter clean && flutter pub get`
- Check Flutter version compatibility
- Ensure all dependencies are properly installed

**4. Data Not Saving**
- Check server logs for errors
- Verify database permissions
- Test API endpoints manually using the docs interface

### Getting Help

1. **Check the logs**: Server console output shows detailed errors
2. **Test API manually**: Use http://localhost:8000/docs to test endpoints
3. **Verify database**: Connect directly to PostgreSQL and check tables
4. **Review configuration**: Ensure all environment variables are set correctly

## 🎉 Next Steps

Once you have the basic system running:

1. **Collect signature samples**: Gather diverse signature data
2. **Analyze patterns**: Use the ML export tools to explore data
3. **Train models**: Use exported data for signature verification/detection
4. **Customize features**: Add new metrics or analysis capabilities
5. **Scale deployment**: Move to production servers and cloud databases

## 📈 Performance Tips

- **Database optimization**: Add indexes for frequently queried fields
- **Batch uploads**: Group multiple signatures for bulk upload
- **Caching**: Implement Redis for frequently accessed data
- **Load balancing**: Use multiple server instances for high traffic
- **Mobile optimization**: Implement offline storage with sync capabilities
