# Bank Fraud Detection FastAPI Server

> **IMPORTANT NOTE**: This directory contains the **legacy v1 server** that uses an XGBoost baseline model (`app.py`). The **main production server** for the Beyond Rules project uses a Graph Neural Network (GNN) and is located in the `gnn-server/` subdirectory (`gnn-server/app2.py`).

This FastAPI server provides a RESTful API for detecting fraudulent bank transactions using a trained XGBoost model.

## Setup Instructions

### 1. First, train and save your model

Run the notebook `bank_fraud_detection.ipynb` to train the XGBoost model and save it. The notebook will create:
- `fraud_detection_model.pkl` - The trained XGBoost model
- `feature_columns.pkl` - The feature column names for preprocessing

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Run the FastAPI server

```bash
python app.py
```

Or using uvicorn directly:
```bash
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

The server will start on `http://localhost:8000`

## API Endpoints

### Health Check
- **GET** `/` - Basic health check
- **GET** `/health` - Detailed health check with model status

### Predictions
- **POST** `/predict` - Predict fraud for a single transaction
- **POST** `/predict_batch` - Predict fraud for multiple transactions

### Model Information
- **GET** `/model_info` - Get information about the loaded model

## API Documentation

Once the server is running, you can access:
- Interactive API docs: `http://localhost:8000/docs`
- ReDoc documentation: `http://localhost:8000/redoc`

## Request Format

### Single Transaction Prediction

```json
{
    "inr_amount": 15000.0,
    "txn_count_customer": 5,
    "is_high_amount": 1,
    "category_fraud_rate": 0.15,
    "txn_count_category": 1000,
    "customer_fraud_rate": 0.0,
    "merchant_fraud_rate": 0.05,
    "txn_count_merch": 3,
    "category_features": {
        "categoy__es_transportation": 1,
        "categoy__es_food_dining": 0,
        "categoy__es_gas_transport": 0
    }
}
```

### Response Format

```json
{
    "is_fraud": true,
    "fraud_probability": 0.8542,
    "confidence_level": "High"
}
```

## Testing the API

Use the provided test script:

```bash
python test_api.py
```

This will test all endpoints and show example responses.

## Features

- **Single Transaction Prediction**: Predict fraud for individual transactions
- **Batch Processing**: Process multiple transactions in a single request
- **Confidence Levels**: Get confidence levels (High/Medium/Low) based on probability scores
- **Model Information**: Retrieve information about the loaded model
- **Error Handling**: Comprehensive error handling and logging
- **Automatic Documentation**: Interactive API documentation with Swagger UI

## Model Features

The model expects the following features:
- `inr_amount`: Transaction amount in INR
- `txn_count_customer`: Number of previous transactions by the customer
- `is_high_amount`: Binary flag for high amount transactions (1/0)
- `category_fraud_rate`: Historical fraud rate for the transaction category
- `txn_count_category`: Total transactions in the category
- `customer_fraud_rate`: Historical fraud rate for the customer
- `merchant_fraud_rate`: Historical fraud rate for the merchant
- `txn_count_merch`: Number of transactions by the merchant
- Category one-hot encoded features (dynamically handled)

## Notes

- The server automatically handles missing category features by setting them to 0
- All feature columns are reordered to match the training data format
- The model uses a threshold of 0.5 for fraud classification
- Confidence levels are based on probability scores: High (≥0.8), Medium (≥0.6), Low (<0.6)
