# FastAPI server for signature data collection
# This server receives signature data from the Flutter app and stores it in PostgreSQL

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import psycopg2
from psycopg2.extras import RealDictCursor
import json
from datetime import datetime
from contextlib import contextmanager, asynccontextmanager

# Database configuration - hardcoded as requested
DATABASE_CONFIG = {
    "host": "localhost",
    "database": "postgres",
    "user": "postgres",
    "password": "root",
    "port": 5432
}

def parse_timestamp(timestamp_str: str) -> datetime:
    """Parse timestamp string with better error handling"""
    try:
        # Handle different timestamp formats
        if timestamp_str.endswith('Z'):
            return datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        elif '+' in timestamp_str or timestamp_str.endswith('00:00'):
            return datetime.fromisoformat(timestamp_str)
        else:
            # Assume UTC if no timezone info
            return datetime.fromisoformat(timestamp_str + '+00:00')
    except ValueError as e:
        raise ValueError(f"Invalid timestamp format: {timestamp_str}. Error: {e}")

def validate_database_config():
    """Validate database configuration"""
    try:
        conn = psycopg2.connect(**DATABASE_CONFIG)
        conn.close()
        print("Database connection test successful")
    except psycopg2.Error as e:
        raise ValueError(f"Database connection test failed: {e}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    try:
        validate_database_config()
        init_database()
        print("Database initialized successfully")
    except Exception as e:
        print(f"Database initialization failed: {e}")
        # Don't raise here to allow server to start even if DB is not ready
    yield
    # Shutdown (if needed)

app = FastAPI(title="Signature Collection API", version="1.0.0", lifespan=lifespan)

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class SignaturePoint(BaseModel):
    x: float
    y: float
    pressure: float
    timestamp: str
    velocity: Optional[float] = None
    acceleration: Optional[float] = None

class SignatureStroke(BaseModel):
    points: List[SignaturePoint]
    startTime: str
    endTime: str
    averageSpeed: float
    totalDistance: float
    averagePressure: float
    duration: Optional[int] = None

class SignatureMetadata(BaseModel):
    totalDuration: float
    totalStrokes: int
    totalPoints: int
    averageStrokeSpeed: float
    averagePressure: float
    signatureWidth: float
    signatureHeight: float
    strokeDensity: float

class SignatureData(BaseModel):
    id: str
    strokes: List[SignatureStroke]
    createdAt: str
    canvasWidth: float
    canvasHeight: float
    deviceInfo: Dict[str, Any]
    metadata: SignatureMetadata

@contextmanager
def get_db_connection():
    """Database connection context manager"""
    conn = None
    try:
        conn = psycopg2.connect(**DATABASE_CONFIG)
        yield conn
    except psycopg2.OperationalError as e:
        if conn:
            conn.rollback()
        raise HTTPException(status_code=503, detail=f"Database connection failed: {str(e)}")
    except psycopg2.Error as e:
        if conn:
            conn.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        if conn:
            conn.rollback()
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    finally:
        if conn:
            conn.close()

def init_database():
    """Initialize database tables"""
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Create signatures table
            cur.execute("""
                CREATE TABLE IF NOT EXISTS signatures (
                    id VARCHAR(255) PRIMARY KEY,
                    created_at TIMESTAMP,
                    canvas_width FLOAT,
                    canvas_height FLOAT,
                    device_info JSONB,
                    metadata JSONB,
                    strokes JSONB,
                    total_duration FLOAT,
                    total_strokes INTEGER,
                    total_points INTEGER,
                    average_stroke_speed FLOAT,
                    average_pressure FLOAT,
                    signature_width FLOAT,
                    signature_height FLOAT,
                    stroke_density FLOAT
                )
            """)
            
            # Create signature_points table for detailed analysis
            cur.execute("""
                CREATE TABLE IF NOT EXISTS signature_points (
                    id SERIAL PRIMARY KEY,
                    signature_id VARCHAR(255) REFERENCES signatures(id),
                    stroke_index INTEGER,
                    point_index INTEGER,
                    x FLOAT,
                    y FLOAT,
                    pressure FLOAT,
                    timestamp TIMESTAMP,
                    velocity FLOAT,
                    acceleration FLOAT
                )
            """)
            
            # Create indexes for better query performance
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_signatures_created_at ON signatures(created_at);
                CREATE INDEX IF NOT EXISTS idx_signature_points_signature_id ON signature_points(signature_id);
            """)
            
            conn.commit()

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unavailable: {str(e)}")

@app.post("/signatures")
async def create_signature(signature: SignatureData):
    """Store a new signature in the database"""
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # Insert main signature record
                cur.execute("""
                    INSERT INTO signatures (
                        id, created_at, canvas_width, canvas_height, device_info, 
                        metadata, strokes, total_duration, total_strokes, total_points,
                        average_stroke_speed, average_pressure, signature_width,
                        signature_height, stroke_density
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    signature.id,
                    parse_timestamp(signature.createdAt),
                    signature.canvasWidth,
                    signature.canvasHeight,
                    json.dumps(signature.deviceInfo),
                    json.dumps(signature.metadata.model_dump()),
                    json.dumps([stroke.model_dump() for stroke in signature.strokes]),
                    signature.metadata.totalDuration,
                    signature.metadata.totalStrokes,
                    signature.metadata.totalPoints,
                    signature.metadata.averageStrokeSpeed,
                    signature.metadata.averagePressure,
                    signature.metadata.signatureWidth,
                    signature.metadata.signatureHeight,
                    signature.metadata.strokeDensity
                ))
                
                # Insert detailed point data for ML training
                for stroke_idx, stroke in enumerate(signature.strokes):
                    for point_idx, point in enumerate(stroke.points):
                        cur.execute("""
                            INSERT INTO signature_points (
                                signature_id, stroke_index, point_index, x, y, 
                                pressure, timestamp, velocity, acceleration
                            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """, (
                            signature.id,
                            stroke_idx,
                            point_idx,
                            point.x,
                            point.y,
                            point.pressure,
                            parse_timestamp(point.timestamp),
                            point.velocity,
                            point.acceleration
                        ))
                
                conn.commit()
                
        return {"message": "Signature stored successfully", "id": signature.id}
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid data: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to store signature: {str(e)}")

@app.get("/signatures")
async def get_signatures(limit: int = 50, offset: int = 0):
    """Retrieve signatures from the database"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT id, created_at, canvas_width, canvas_height, 
                           device_info, metadata, strokes
                    FROM signatures 
                    ORDER BY created_at DESC 
                    LIMIT %s OFFSET %s
                """, (limit, offset))
                
                signatures = cur.fetchall()
                
                # Convert to proper format
                result = []
                for sig in signatures:
                    result.append({
                        "id": sig["id"],
                        "createdAt": sig["created_at"].isoformat(),
                        "canvasWidth": sig["canvas_width"],
                        "canvasHeight": sig["canvas_height"],
                        "deviceInfo": sig["device_info"],
                        "metadata": sig["metadata"],
                        "strokes": sig["strokes"]
                    })
                
                return result
                
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve signatures: {str(e)}")

@app.get("/signatures/{signature_id}")
async def get_signature(signature_id: str):
    """Retrieve a specific signature by ID"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT id, created_at, canvas_width, canvas_height, 
                           device_info, metadata, strokes
                    FROM signatures 
                    WHERE id = %s
                """, (signature_id,))
                
                signature = cur.fetchone()
                
                if not signature:
                    raise HTTPException(status_code=404, detail="Signature not found")
                
                return {
                    "id": signature["id"],
                    "createdAt": signature["created_at"].isoformat(),
                    "canvasWidth": signature["canvas_width"],
                    "canvasHeight": signature["canvas_height"],
                    "deviceInfo": signature["device_info"],
                    "metadata": signature["metadata"],
                    "strokes": signature["strokes"]
                }
                
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve signature: {str(e)}")

@app.get("/signatures/{signature_id}/analysis")
async def get_signature_analysis(signature_id: str):
    """Get detailed analysis of a signature for ML training"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Get basic signature info
                cur.execute("""
                    SELECT * FROM signatures WHERE id = %s
                """, (signature_id,))
                
                signature = cur.fetchone()
                if not signature:
                    raise HTTPException(status_code=404, detail="Signature not found")
                
                # Get detailed point data
                cur.execute("""
                    SELECT stroke_index, point_index, x, y, pressure, 
                           timestamp, velocity, acceleration
                    FROM signature_points 
                    WHERE signature_id = %s 
                    ORDER BY stroke_index, point_index
                """, (signature_id,))
                
                points = cur.fetchall()
                
                # Group points by stroke
                strokes_data = {}
                for point in points:
                    stroke_idx = point["stroke_index"]
                    if stroke_idx not in strokes_data:
                        strokes_data[stroke_idx] = []
                    strokes_data[stroke_idx].append({
                        "x": point["x"],
                        "y": point["y"],
                        "pressure": point["pressure"],
                        "timestamp": point["timestamp"].isoformat(),
                        "velocity": point["velocity"],
                        "acceleration": point["acceleration"]
                    })
                
                return {
                    "signature_id": signature_id,
                    "metadata": signature["metadata"],
                    "strokes_analysis": strokes_data,
                    "ml_features": {
                        "total_duration": signature["total_duration"],
                        "total_strokes": signature["total_strokes"],
                        "total_points": signature["total_points"],
                        "average_stroke_speed": signature["average_stroke_speed"],
                        "average_pressure": signature["average_pressure"],
                        "stroke_density": signature["stroke_density"],
                        "aspect_ratio": signature["signature_width"] / max(signature["signature_height"], 1)
                    }
                }
                
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to analyze signature: {str(e)}")

@app.get("/statistics")
async def get_statistics():
    """Get database statistics"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT 
                        COUNT(*) as total_signatures,
                        AVG(total_duration) as avg_duration,
                        AVG(total_strokes) as avg_strokes,
                        AVG(total_points) as avg_points,
                        AVG(average_pressure) as avg_pressure,
                        MIN(created_at) as earliest_signature,
                        MAX(created_at) as latest_signature
                    FROM signatures
                """)
                
                stats = cur.fetchone()
                
                return {
                    "total_signatures": stats["total_signatures"],
                    "average_duration_ms": float(stats["avg_duration"]) if stats["avg_duration"] else 0,
                    "average_strokes": float(stats["avg_strokes"]) if stats["avg_strokes"] else 0,
                    "average_points": float(stats["avg_points"]) if stats["avg_points"] else 0,
                    "average_pressure": float(stats["avg_pressure"]) if stats["avg_pressure"] else 0,
                    "earliest_signature": stats["earliest_signature"].isoformat() if stats["earliest_signature"] else None,
                    "latest_signature": stats["latest_signature"].isoformat() if stats["latest_signature"] else None
                }
                
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get statistics: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
