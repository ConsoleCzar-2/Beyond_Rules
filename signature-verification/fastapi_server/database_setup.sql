-- Signature Collection Database Setup
-- Run this script to set up the PostgreSQL database for signature collection

-- Create database (run as postgres superuser)
-- CREATE DATABASE signature_db;

-- Connect to the signature_db database before running the rest

-- Create signatures table
CREATE TABLE IF NOT EXISTS signatures (
    id VARCHAR(255) PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    canvas_width FLOAT NOT NULL,
    canvas_height FLOAT NOT NULL,
    device_info JSONB,
    metadata JSONB,
    strokes JSONB,
    -- Extracted ML features for quick access
    total_duration FLOAT,
    total_strokes INTEGER,
    total_points INTEGER,
    average_stroke_speed FLOAT,
    average_pressure FLOAT,
    signature_width FLOAT,
    signature_height FLOAT,
    stroke_density FLOAT
);

-- Create signature_points table for detailed point analysis
CREATE TABLE IF NOT EXISTS signature_points (
    id SERIAL PRIMARY KEY,
    signature_id VARCHAR(255) REFERENCES signatures(id) ON DELETE CASCADE,
    stroke_index INTEGER NOT NULL,
    point_index INTEGER NOT NULL,
    x FLOAT NOT NULL,
    y FLOAT NOT NULL,
    pressure FLOAT NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    velocity FLOAT,
    acceleration FLOAT,
    CONSTRAINT unique_point UNIQUE (signature_id, stroke_index, point_index)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_signatures_created_at ON signatures(created_at);
CREATE INDEX IF NOT EXISTS idx_signatures_duration ON signatures(total_duration);
CREATE INDEX IF NOT EXISTS idx_signatures_strokes ON signatures(total_strokes);
CREATE INDEX IF NOT EXISTS idx_signature_points_signature_id ON signature_points(signature_id);
CREATE INDEX IF NOT EXISTS idx_signature_points_stroke ON signature_points(signature_id, stroke_index);
CREATE INDEX IF NOT EXISTS idx_signature_points_timestamp ON signature_points(timestamp);

-- Create a view for ML feature extraction
CREATE OR REPLACE VIEW signature_ml_features AS
SELECT 
    s.id,
    s.created_at,
    s.total_duration,
    s.total_strokes,
    s.total_points,
    s.average_stroke_speed,
    s.average_pressure,
    s.signature_width,
    s.signature_height,
    s.stroke_density,
    s.canvas_width,
    s.canvas_height,
    -- Calculated features
    (s.signature_width / NULLIF(s.signature_height, 0)) AS aspect_ratio,
    (s.total_points::FLOAT / NULLIF(s.total_strokes, 0)) AS avg_points_per_stroke,
    (s.total_duration / NULLIF(s.total_strokes, 0)) AS avg_stroke_duration,
    (s.signature_width * s.signature_height) AS signature_area,
    ((s.signature_width * s.signature_height) / NULLIF(s.canvas_width * s.canvas_height, 0)) AS canvas_coverage
FROM signatures s;

-- Create a function to get signature statistics
CREATE OR REPLACE FUNCTION get_signature_stats()
RETURNS TABLE (
    total_signatures BIGINT,
    avg_duration NUMERIC,
    avg_strokes NUMERIC,
    avg_points NUMERIC,
    avg_pressure NUMERIC,
    avg_speed NUMERIC,
    min_date TIMESTAMP,
    max_date TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT,
        ROUND(AVG(s.total_duration), 2),
        ROUND(AVG(s.total_strokes), 2),
        ROUND(AVG(s.total_points), 2),
        ROUND(AVG(s.average_pressure), 3),
        ROUND(AVG(s.average_stroke_speed), 2),
        MIN(s.created_at),
        MAX(s.created_at)
    FROM signatures s;
END;
$$ LANGUAGE plpgsql;

-- Create sample queries for data analysis

-- Query 1: Get signature complexity distribution
-- SELECT 
--     CASE 
--         WHEN total_strokes <= 5 THEN 'Simple (1-5 strokes)'
--         WHEN total_strokes <= 10 THEN 'Moderate (6-10 strokes)'
--         WHEN total_strokes <= 20 THEN 'Complex (11-20 strokes)'
--         ELSE 'Very Complex (20+ strokes)'
--     END as complexity,
--     COUNT(*) as count,
--     AVG(total_duration) as avg_duration
-- FROM signatures 
-- GROUP BY 
--     CASE 
--         WHEN total_strokes <= 5 THEN 'Simple (1-5 strokes)'
--         WHEN total_strokes <= 10 THEN 'Moderate (6-10 strokes)'
--         WHEN total_strokes <= 20 THEN 'Complex (11-20 strokes)'
--         ELSE 'Very Complex (20+ strokes)'
--     END
-- ORDER BY count DESC;

-- Query 2: Get pressure analysis
-- SELECT 
--     id,
--     total_strokes,
--     average_pressure,
--     (SELECT AVG(pressure) FROM signature_points WHERE signature_id = s.id) as actual_avg_pressure,
--     (SELECT STDDEV(pressure) FROM signature_points WHERE signature_id = s.id) as pressure_variance
-- FROM signatures s
-- ORDER BY average_pressure DESC;

-- Query 3: Get temporal patterns
-- SELECT 
--     EXTRACT(HOUR FROM created_at) as hour_of_day,
--     COUNT(*) as signature_count,
--     AVG(total_duration) as avg_duration,
--     AVG(average_stroke_speed) as avg_speed
-- FROM signatures 
-- GROUP BY EXTRACT(HOUR FROM created_at)
-- ORDER BY hour_of_day;

COMMENT ON TABLE signatures IS 'Main signatures table containing signature metadata and ML features';
COMMENT ON TABLE signature_points IS 'Detailed point data for each signature stroke';
COMMENT ON VIEW signature_ml_features IS 'Pre-calculated ML features for signature analysis';
COMMENT ON FUNCTION get_signature_stats IS 'Returns overall database statistics';

-- Grant permissions (adjust as needed for your setup)
-- GRANT ALL PRIVILEGES ON signatures TO signature_user;
-- GRANT ALL PRIVILEGES ON signature_points TO signature_user;
-- GRANT ALL PRIVILEGES ON signature_ml_features TO signature_user;
