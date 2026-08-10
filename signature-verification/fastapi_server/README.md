# Signature Collection API

This FastAPI server collects signature data from the Flutter app and stores it in a PostgreSQL database for ML model training.

## Features

- **Comprehensive Data Collection**: Captures stroke patterns, speed, pressure, and timing data
- **PostgreSQL Storage**: Structured storage optimized for ML training
- **RESTful API**: Easy integration with the Flutter app
- **Real-time Analysis**: Provides immediate feedback on signature characteristics
- **ML-Ready Data**: Exports data in formats suitable for machine learning

## Setup Instructions

### Prerequisites

- Python 3.8+
- PostgreSQL 12+
- pip

### Installation

1. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up PostgreSQL:**
   ```sql
   -- Create database
   CREATE DATABASE signature_db;
   
   -- Create user (optional)
   CREATE USER signature_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE signature_db TO signature_user;
   ```

3. **Configure environment variables:**
   ```bash
   export DB_HOST=localhost
   export DB_NAME=signature_db
   export DB_USER=postgres
   export DB_PASSWORD=your_password
   export DB_PORT=5432
   ```

### Running the Server

```bash
python main.py
```

The server will start on `http://localhost:8000`

### API Documentation

Once running, visit `http://localhost:8000/docs` for interactive API documentation.

## API Endpoints

### Health Check
- `GET /health` - Check server and database status

### Signatures
- `POST /signatures` - Store a new signature
- `GET /signatures` - Retrieve signatures (with pagination)
- `GET /signatures/{id}` - Get specific signature
- `GET /signatures/{id}/analysis` - Get detailed ML analysis

### Statistics
- `GET /statistics` - Get database statistics

## Database Schema

### Signatures Table
Stores main signature metadata:
- `id`: Unique signature identifier
- `created_at`: Timestamp
- `canvas_width/height`: Drawing area dimensions
- `device_info`: Device and platform information
- `metadata`: Calculated signature metrics
- `strokes`: Complete stroke data (JSONB)
- ML features: `total_duration`, `total_strokes`, `total_points`, etc.

### Signature Points Table
Stores individual point data for detailed analysis:
- `signature_id`: Foreign key to signatures
- `stroke_index`: Stroke number within signature
- `point_index`: Point number within stroke
- `x, y`: Coordinates
- `pressure`: Pressure value (0-1)
- `timestamp`: Point capture time
- `velocity`: Point velocity (pixels/second)
- `acceleration`: Point acceleration

## ML Features Captured

The system captures comprehensive data for signature analysis:

### Temporal Features
- Total signature duration
- Individual stroke durations
- Inter-stroke intervals
- Point capture timestamps

### Spatial Features
- Stroke coordinates and paths
- Signature bounding box
- Stroke density
- Aspect ratio

### Dynamic Features
- Stroke velocity profiles
- Acceleration patterns
- Pressure variations
- Speed consistency

### Statistical Features
- Average pressure per stroke
- Speed distribution
- Stroke count and complexity
- Point density

## Data Export for ML

The stored data can be easily exported for machine learning:

```python
# Example: Export signature features
import psycopg2
import pandas as pd

conn = psycopg2.connect(...)
df = pd.read_sql("""
    SELECT 
        id,
        total_duration,
        total_strokes,
        total_points,
        average_stroke_speed,
        average_pressure,
        signature_width,
        signature_height,
        stroke_density
    FROM signatures
""", conn)
```

## Security Considerations

For production deployment:

1. **Environment Variables**: Store database credentials securely
2. **CORS Configuration**: Restrict allowed origins
3. **Authentication**: Add API authentication if needed
4. **Database Security**: Use connection pooling and prepared statements
5. **Data Privacy**: Implement data anonymization if required

## Monitoring and Maintenance

- Monitor database size and performance
- Regular backups of signature data
- Log analysis for usage patterns
- Performance optimization for large datasets
