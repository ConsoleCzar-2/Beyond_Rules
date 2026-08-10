"""
ML Data Export Script for Signature Analysis
============================================

This script exports signature data from the PostgreSQL database in formats
suitable for machine learning training and analysis.

Usage:
    python ml_export.py --format csv --output signatures_dataset.csv
    python ml_export.py --format json --output signatures_dataset.json
    python ml_export.py --format numpy --output signatures_arrays.npz
"""

import argparse
import json
import numpy as np
import pandas as pd
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from datetime import datetime

# Database configuration
DATABASE_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "database": os.getenv("DB_NAME", "signature_db"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "password"),
    "port": os.getenv("DB_PORT", "5432")
}

def get_signature_features():
    """Export signature-level features for ML training"""
    query = """
    SELECT 
        id,
        total_duration,
        total_strokes,
        total_points,
        average_stroke_speed,
        average_pressure,
        signature_width,
        signature_height,
        stroke_density,
        canvas_width,
        canvas_height,
        (signature_width / NULLIF(signature_height, 0)) AS aspect_ratio,
        (total_points::FLOAT / NULLIF(total_strokes, 0)) AS avg_points_per_stroke,
        (total_duration / NULLIF(total_strokes, 0)) AS avg_stroke_duration,
        (signature_width * signature_height) AS signature_area,
        ((signature_width * signature_height) / NULLIF(canvas_width * canvas_height, 0)) AS canvas_coverage,
        created_at
    FROM signatures
    ORDER BY created_at
    """
    
    with psycopg2.connect(**DATABASE_CONFIG) as conn:
        return pd.read_sql(query, conn)

def get_stroke_features():
    """Export stroke-level features"""
    query = """
    SELECT 
        s.id as signature_id,
        stroke_idx,
        stroke_data->>'startTime' as start_time,
        stroke_data->>'endTime' as end_time,
        (stroke_data->>'averageSpeed')::FLOAT as average_speed,
        (stroke_data->>'totalDistance')::FLOAT as total_distance,
        (stroke_data->>'averagePressure')::FLOAT as average_pressure,
        (stroke_data->>'duration')::INT as duration,
        jsonb_array_length(stroke_data->'points') as point_count
    FROM signatures s,
         jsonb_array_elements_with_ordinality(s.strokes) AS stroke_data(stroke_data, stroke_idx)
    ORDER BY s.created_at, stroke_idx
    """
    
    with psycopg2.connect(**DATABASE_CONFIG) as conn:
        return pd.read_sql(query, conn)

def get_point_sequences():
    """Export point sequences for time-series analysis"""
    query = """
    SELECT 
        signature_id,
        stroke_index,
        array_agg(x ORDER BY point_index) as x_sequence,
        array_agg(y ORDER BY point_index) as y_sequence,
        array_agg(pressure ORDER BY point_index) as pressure_sequence,
        array_agg(velocity ORDER BY point_index) as velocity_sequence,
        array_agg(acceleration ORDER BY point_index) as acceleration_sequence,
        array_agg(EXTRACT(EPOCH FROM timestamp) ORDER BY point_index) as timestamp_sequence
    FROM signature_points
    GROUP BY signature_id, stroke_index
    ORDER BY signature_id, stroke_index
    """
    
    with psycopg2.connect(**DATABASE_CONFIG) as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query)
            return cur.fetchall()

def export_to_csv(output_file):
    """Export signature features to CSV"""
    print("Exporting signature features to CSV...")
    
    # Get signature-level features
    signature_df = get_signature_features()
    
    # Get stroke-level features aggregated per signature
    stroke_df = get_stroke_features()
    stroke_agg = stroke_df.groupby('signature_id').agg({
        'average_speed': ['mean', 'std', 'min', 'max'],
        'total_distance': ['sum', 'mean', 'std'],
        'average_pressure': ['mean', 'std', 'min', 'max'],
        'duration': ['sum', 'mean', 'std'],
        'point_count': ['sum', 'mean', 'std']
    }).round(4)
    
    # Flatten column names
    stroke_agg.columns = [f'stroke_{stat}_{col}' for col, stat in stroke_agg.columns]
    stroke_agg = stroke_agg.reset_index()
    
    # Merge datasets
    ml_dataset = signature_df.merge(stroke_agg, left_on='id', right_on='signature_id', how='left')
    ml_dataset = ml_dataset.drop('signature_id', axis=1)
    
    # Save to CSV
    ml_dataset.to_csv(output_file, index=False)
    print(f"Exported {len(ml_dataset)} signatures to {output_file}")
    print(f"Features: {list(ml_dataset.columns)}")

def export_to_json(output_file):
    """Export complete signature data to JSON"""
    print("Exporting complete signature data to JSON...")
    
    query = """
    SELECT 
        id,
        created_at,
        canvas_width,
        canvas_height,
        device_info,
        metadata,
        strokes
    FROM signatures
    ORDER BY created_at
    """
    
    with psycopg2.connect(**DATABASE_CONFIG) as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query)
            signatures = cur.fetchall()
    
    # Convert to JSON-serializable format
    json_data = []
    for sig in signatures:
        json_data.append({
            'id': sig['id'],
            'created_at': sig['created_at'].isoformat(),
            'canvas_width': sig['canvas_width'],
            'canvas_height': sig['canvas_height'],
            'device_info': sig['device_info'],
            'metadata': sig['metadata'],
            'strokes': sig['strokes']
        })
    
    with open(output_file, 'w') as f:
        json.dump(json_data, f, indent=2)
    
    print(f"Exported {len(json_data)} signatures to {output_file}")

def export_to_numpy(output_file):
    """Export point sequences as NumPy arrays"""
    print("Exporting point sequences to NumPy format...")
    
    # Get signature features
    signature_df = get_signature_features()
    
    # Get point sequences
    sequences = get_point_sequences()
    
    # Prepare arrays
    signature_ids = []
    x_sequences = []
    y_sequences = []
    pressure_sequences = []
    velocity_sequences = []
    features = []
    
    for seq in sequences:
        signature_ids.append(seq['signature_id'])
        x_sequences.append(np.array(seq['x_sequence']))
        y_sequences.append(np.array(seq['y_sequence']))
        pressure_sequences.append(np.array(seq['pressure_sequence']))
        velocity_sequences.append(np.array([v for v in seq['velocity_sequence'] if v is not None]))
        
    # Get corresponding features
    features_array = signature_df.set_index('id').loc[
        [sid for sid in signature_ids if sid in signature_df['id'].values]
    ].select_dtypes(include=[np.number]).values
    
    # Save as NPZ file
    np.savez_compressed(
        output_file,
        signature_ids=np.array(signature_ids),
        x_sequences=np.array(x_sequences, dtype=object),
        y_sequences=np.array(y_sequences, dtype=object),
        pressure_sequences=np.array(pressure_sequences, dtype=object),
        velocity_sequences=np.array(velocity_sequences, dtype=object),
        features=features_array,
        feature_names=signature_df.select_dtypes(include=[np.number]).columns.tolist()
    )
    
    print(f"Exported {len(signature_ids)} stroke sequences to {output_file}")
    print(f"Arrays: signature_ids, x_sequences, y_sequences, pressure_sequences, velocity_sequences, features")

def generate_ml_report():
    """Generate a summary report of the dataset"""
    print("\n" + "="*50)
    print("SIGNATURE DATASET SUMMARY REPORT")
    print("="*50)
    
    try:
        # Basic statistics
        signature_df = get_signature_features()
        stroke_df = get_stroke_features()
        
        print(f"\nDataset Overview:")
        print(f"- Total Signatures: {len(signature_df)}")
        print(f"- Total Strokes: {len(stroke_df)}")
        print(f"- Date Range: {signature_df['created_at'].min()} to {signature_df['created_at'].max()}")
        
        print(f"\nSignature Characteristics:")
        print(f"- Avg Duration: {signature_df['total_duration'].mean():.1f}ms")
        print(f"- Avg Strokes per Signature: {signature_df['total_strokes'].mean():.1f}")
        print(f"- Avg Points per Signature: {signature_df['total_points'].mean():.1f}")
        print(f"- Avg Pressure: {signature_df['average_pressure'].mean():.3f}")
        print(f"- Avg Speed: {signature_df['average_stroke_speed'].mean():.1f} px/s")
        
        print(f"\nComplexity Distribution:")
        complexity_dist = pd.cut(signature_df['total_strokes'], 
                               bins=[0, 5, 10, 20, float('inf')], 
                               labels=['Simple (1-5)', 'Moderate (6-10)', 'Complex (11-20)', 'Very Complex (20+)']).value_counts()
        for category, count in complexity_dist.items():
            print(f"- {category}: {count} signatures ({count/len(signature_df)*100:.1f}%)")
        
        print(f"\nML Features Available:")
        numeric_cols = signature_df.select_dtypes(include=[np.number]).columns
        print(f"- Signature-level features: {len(numeric_cols)}")
        print(f"- Stroke-level features: Available for aggregation")
        print(f"- Point-level sequences: X, Y, pressure, velocity, acceleration")
        
    except Exception as e:
        print(f"Error generating report: {e}")

def main():
    parser = argparse.ArgumentParser(description='Export signature data for ML training')
    parser.add_argument('--format', choices=['csv', 'json', 'numpy', 'all'], 
                       default='csv', help='Export format')
    parser.add_argument('--output', default='signatures_export', 
                       help='Output file prefix (extension will be added automatically)')
    parser.add_argument('--report', action='store_true', 
                       help='Generate summary report')
    
    args = parser.parse_args()
    
    if args.report:
        generate_ml_report()
        return
    
    try:
        if args.format == 'csv' or args.format == 'all':
            export_to_csv(f"{args.output}.csv")
        
        if args.format == 'json' or args.format == 'all':
            export_to_json(f"{args.output}.json")
        
        if args.format == 'numpy' or args.format == 'all':
            export_to_numpy(f"{args.output}.npz")
        
        print(f"\nExport completed successfully!")
        
        # Generate report after export
        if args.format == 'all':
            generate_ml_report()
            
    except Exception as e:
        print(f"Error during export: {e}")

if __name__ == "__main__":
    main()
