# Advanced Signature Capture System

A comprehensive Flutter application that captures detailed signature data with stroke patterns, speed, pressure, and timing information for ML model training. The captured data is automatically sent to a FastAPI server and stored in a PostgreSQL database.

## Features

### Flutter App Features
- **Advanced Signature Capture**: Real-time drawing with pressure sensitivity
- **Comprehensive Data Collection**: Captures stroke patterns, velocity, acceleration, and pressure
- **Smart Analysis**: Automatic calculation of signature metrics and characteristics
- **Real-time Feedback**: Live display of stroke count, points, and timing
- **Server Integration**: Automatic upload to FastAPI backend
- **Offline Support**: Local storage when server is unavailable
- **Visual Feedback**: Dynamic stroke rendering with pressure-based styling

### Captured Data Points
- **Temporal Data**: Stroke timing, duration, inter-stroke intervals
- **Spatial Data**: X/Y coordinates, stroke paths, bounding boxes
- **Dynamic Data**: Velocity profiles, acceleration patterns, pressure variations
- **Metadata**: Device info, canvas dimensions, signature statistics

### Backend Features
- **RESTful API**: FastAPI server with automatic documentation
- **PostgreSQL Storage**: Optimized database schema for ML training
- **Real-time Analysis**: Immediate signature characteristic analysis
- **Data Export**: ML-ready data formats
- **Statistics Dashboard**: Comprehensive usage and performance metrics

## App Interface

The Flutter app provides an intuitive interface with:
- Large signature canvas with real-time drawing
- Clear/Save signature controls
- Server connection status indicator
- Recent signatures gallery
- Detailed signature statistics display
- Success/error feedback dialogs

## Installation & Setup

### Flutter App Setup

1. **Install Flutter dependencies:**
   ```bash
   cd signature_test
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

### FastAPI Server Setup

1. **Navigate to server directory:**
   ```bash
   cd fastapi_server
   ```

2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Set up PostgreSQL:**
   ```sql
   CREATE DATABASE signature_db;
   ```

4. **Configure environment variables:**
   ```bash
   export DB_HOST=localhost
   export DB_NAME=signature_db
   export DB_USER=postgres
   export DB_PASSWORD=your_password
   ```

5. **Run the server:**
   ```bash
   python main.py
   ```

### Docker Setup (Alternative)

```bash
cd fastapi_server
docker-compose up -d
```

## Data Structure

### Signature Data Model

```dart
class SignatureData {
  String id;                    // Unique identifier
  List<SignatureStroke> strokes; // All drawing strokes
  DateTime createdAt;           // Creation timestamp
  double canvasWidth/Height;    // Drawing area dimensions
  Map deviceInfo;               // Device/platform info
  SignatureMetadata metadata;   // Calculated metrics
}
```

### Stroke Data Model

```dart
class SignatureStroke {
  List<SignaturePoint> points;  // Individual points
  DateTime startTime/endTime;   // Stroke timing
  double averageSpeed;          // Stroke velocity
  double totalDistance;         // Stroke length
  double averagePressure;       // Pressure profile
}
```

### Point Data Model

```dart
class SignaturePoint {
  double x, y;                  // Coordinates
  double pressure;              // Pressure (0-1)
  DateTime timestamp;           // Capture time
  double? velocity;             // Point velocity
  double? acceleration;         // Point acceleration
}
```

## ML Features

The system captures rich features suitable for signature analysis:

### Temporal Features
- Total signature duration
- Stroke durations and intervals
- Velocity and acceleration profiles
- Timing consistency patterns

### Spatial Features
- Coordinate sequences and paths
- Bounding box dimensions
- Stroke density and distribution
- Geometric relationships

### Dynamic Features
- Pressure variation patterns
- Speed consistency
- Stroke smoothness
- Direction changes

### Statistical Features
- Average/min/max values for all metrics
- Standard deviations and distributions
- Stroke complexity measures
- Signature uniqueness indicators

## API Endpoints

### Core Endpoints
- `POST /signatures` - Store new signature
- `GET /signatures` - Retrieve signatures (paginated)
- `GET /signatures/{id}` - Get specific signature
- `GET /signatures/{id}/analysis` - Detailed ML analysis

### Utility Endpoints
- `GET /health` - Server health check
- `GET /statistics` - Database statistics

### Example API Usage

```python
import requests

# Upload signature
response = requests.post('http://localhost:8000/signatures', 
                        json=signature_data)

# Get analysis
analysis = requests.get(f'http://localhost:8000/signatures/{signature_id}/analysis')
```

## Database Schema

### Signatures Table
```sql
CREATE TABLE signatures (
    id VARCHAR(255) PRIMARY KEY,
    created_at TIMESTAMP,
    canvas_width FLOAT,
    canvas_height FLOAT,
    device_info JSONB,
    metadata JSONB,
    strokes JSONB,
    -- ML-ready fields
    total_duration FLOAT,
    total_strokes INTEGER,
    total_points INTEGER,
    average_stroke_speed FLOAT,
    average_pressure FLOAT,
    signature_width FLOAT,
    signature_height FLOAT,
    stroke_density FLOAT
);
```

### Signature Points Table
```sql
CREATE TABLE signature_points (
    id SERIAL PRIMARY KEY,
    signature_id VARCHAR(255),
    stroke_index INTEGER,
    point_index INTEGER,
    x FLOAT,
    y FLOAT,
    pressure FLOAT,
    timestamp TIMESTAMP,
    velocity FLOAT,
    acceleration FLOAT
);
```

## Configuration

### Flutter App Configuration
Update `lib/services/signature_api_service.dart`:
```dart
static const String baseUrl = 'http://your-server:8000';
```

### Server Configuration
Set environment variables:
```bash
DB_HOST=localhost
DB_NAME=signature_db
DB_USER=postgres
DB_PASSWORD=your_password
DB_PORT=5432
```

## Deployment

### Production Server Deployment
1. Set up PostgreSQL database
2. Configure environment variables
3. Deploy FastAPI server with gunicorn
4. Set up reverse proxy (nginx)
5. Configure SSL certificates

### Flutter App Deployment
1. Update server URL in configuration
2. Build for target platform:
   ```bash
   flutter build apk          # Android
   flutter build ios          # iOS
   flutter build web          # Web
   ```

## Platform Support

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the [API documentation](http://localhost:8000/docs) when server is running
2. Review the database schema and example queries
3. Test server connection using the health endpoint
4. Check Flutter logs for client-side issues

## Future Enhancements

- [ ] Real-time signature verification
- [ ] Multi-user support with authentication
- [ ] Advanced ML model integration
- [ ] Signature comparison algorithms
- [ ] Export formats for popular ML frameworks
- [ ] Advanced analytics dashboard
- [ ] Batch processing capabilities
- [ ] Cloud storage integration
