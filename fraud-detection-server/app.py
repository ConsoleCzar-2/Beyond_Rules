from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import pandas as pd
import numpy as np
import uvicorn
from typing import Dict, List
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Bank Fraud Detection API",
    description="API for detecting fraudulent bank transactions using XGBoost",
    version="1.0.0"
)

# Global variables for model and feature columns
model = None
feature_columns = None

# Pydantic models for request/response
class TransactionInput(BaseModel):
    inr_amount: float
    txn_count_customer: int
    is_high_amount: int
    category_fraud_rate: float
    txn_count_category: int
    customer_fraud_rate: float
    merchant_fraud_rate: float
    txn_count_merch: int
    # Category one-hot encoded features (will be dynamically handled)
    category_features: Dict[str, int] = {}

class PredictionResponse(BaseModel):
    is_fraud: bool
    fraud_probability: float
    confidence_level: str

class BatchTransactionInput(BaseModel):
    transactions: List[TransactionInput]

class BatchPredictionResponse(BaseModel):
    predictions: List[PredictionResponse]

@app.on_event("startup")
async def load_model():
    """Load the trained model and feature columns on startup"""
    global model, feature_columns
    try:
        model = joblib.load('fraud_detection_model.pkl')
        feature_columns = joblib.load('feature_columns.pkl')
        logger.info("Model and feature columns loaded successfully")
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to load model")

def preprocess_transaction(transaction: TransactionInput) -> pd.DataFrame:
    """Preprocess a single transaction for prediction"""
    # Create a DataFrame with the base features
    data = {
        'inr_amount': transaction.inr_amount,
        'txn_count_customer': transaction.txn_count_customer,
        'is_high_amount': transaction.is_high_amount,
        'category_fraud_rate': transaction.category_fraud_rate,
        'txn_count_category': transaction.txn_count_category,
        'customer_fraud_rate': transaction.customer_fraud_rate,
        'merchant_fraud_rate': transaction.merchant_fraud_rate,
        'txn_count_merch': transaction.txn_count_merch
    }
    
    # Add category features
    data.update(transaction.category_features)
    
    # Create DataFrame
    df = pd.DataFrame([data])
    
    # Ensure all required columns are present with default values
    for col in feature_columns:
        if col not in df.columns:
            df[col] = 0
    
    # Reorder columns to match training data
    df = df[feature_columns]
    
    return df

def get_confidence_level(probability: float) -> str:
    """Determine confidence level based on probability"""
    if probability >= 0.8:
        return "High"
    elif probability >= 0.6:
        return "Medium"
    else:
        return "Low"

@app.get("/")
async def root():
    """Health check endpoint"""
    return {"message": "Bank Fraud Detection API is running"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "model_loaded": model is not None}

@app.post("/predict", response_model=PredictionResponse)
async def predict_fraud(transaction: TransactionInput):
    """Predict fraud for a single transaction"""
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")
    
    try:
        # Preprocess the transaction
        processed_data = preprocess_transaction(transaction)
        
        # Make prediction
        fraud_probability = model.predict_proba(processed_data)[0][1]
        is_fraud = fraud_probability > 0.5
        confidence_level = get_confidence_level(fraud_probability)
        
        return PredictionResponse(
            is_fraud=is_fraud,
            fraud_probability=round(fraud_probability, 4),
            confidence_level=confidence_level
        )
    
    except Exception as e:
        logger.error(f"Error making prediction: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

@app.post("/predict_batch", response_model=BatchPredictionResponse)
async def predict_fraud_batch(batch_input: BatchTransactionInput):
    """Predict fraud for multiple transactions"""
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")
    
    try:
        predictions = []
        
        for transaction in batch_input.transactions:
            # Preprocess the transaction
            processed_data = preprocess_transaction(transaction)
            
            # Make prediction
            fraud_probability = model.predict_proba(processed_data)[0][1]
            is_fraud = fraud_probability > 0.5
            confidence_level = get_confidence_level(fraud_probability)
            
            predictions.append(PredictionResponse(
                is_fraud=is_fraud,
                fraud_probability=round(fraud_probability, 4),
                confidence_level=confidence_level
            ))
        
        return BatchPredictionResponse(predictions=predictions)
    
    except Exception as e:
        logger.error(f"Error making batch predictions: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Batch prediction error: {str(e)}")

@app.get("/model_info")
async def get_model_info():
    """Get information about the loaded model"""
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")
    
    return {
        "model_type": "XGBoost Classifier",
        "number_of_features": len(feature_columns),
        "feature_columns": feature_columns
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
