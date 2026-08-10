import requests
import json

# API base URL
BASE_URL = "http://localhost:8000"

def test_health_check():
    """Test the health check endpoint"""
    response = requests.get(f"{BASE_URL}/health")
    print("Health Check Response:", response.json())

def test_single_prediction():
    """Test single transaction prediction"""
    # Sample transaction data
    transaction = {
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
            # Add other category features as needed
        }
    }
    
    response = requests.post(f"{BASE_URL}/predict", json=transaction)
    print("Single Prediction Response:", response.json())

def test_batch_prediction():
    """Test batch transaction predictions"""
    transactions = {
        "transactions": [
            {
                "inr_amount": 5000.0,
                "txn_count_customer": 2,
                "is_high_amount": 0,
                "category_fraud_rate": 0.05,
                "txn_count_category": 2000,
                "customer_fraud_rate": 0.0,
                "merchant_fraud_rate": 0.02,
                "txn_count_merch": 10,
                "category_features": {
                    "categoy__es_food_dining": 1,
                    "categoy__es_transportation": 0
                }
            },
            {
                "inr_amount": 50000.0,
                "txn_count_customer": 1,
                "is_high_amount": 1,
                "category_fraud_rate": 0.3,
                "txn_count_category": 500,
                "customer_fraud_rate": 0.0,
                "merchant_fraud_rate": 0.2,
                "txn_count_merch": 1,
                "category_features": {
                    "categoy__es_transportation": 1,
                    "categoy__es_food_dining": 0
                }
            }
        ]
    }
    
    response = requests.post(f"{BASE_URL}/predict_batch", json=transactions)
    print("Batch Prediction Response:", response.json())

def test_model_info():
    """Test model information endpoint"""
    response = requests.get(f"{BASE_URL}/model_info")
    print("Model Info Response:", response.json())

if __name__ == "__main__":
    print("Testing Bank Fraud Detection API...")
    
    try:
        test_health_check()
        print("\n" + "="*50 + "\n")
        
        test_model_info()
        print("\n" + "="*50 + "\n")
        
        test_single_prediction()
        print("\n" + "="*50 + "\n")
        
        test_batch_prediction()
        
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to the API. Make sure the server is running on http://localhost:8000")
    except Exception as e:
        print(f"Error: {e}")
