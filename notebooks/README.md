# Training Notebooks — Beyond Rules

This directory contains the consolidated Jupyter notebooks used to train the machine learning models that power the Beyond Rules system.

## Notebooks

### 1. `GNN_Training.ipynb`
- **Purpose**: Trains the Graph Attention Network (GAT) for server-side fraud detection.
- **Library/Framework**: PyTorch, Deep Graph Library (DGL)
- **Dataset**: BankSim (synthetic banking dataset)
- **Output**: Generates the PyTorch model weights (`fraud_gnn.pt`) and scalers used by the FastAPI server in `fraud-detection-server/gnn-server/`.

### 2. `Behavioral_Model.ipynb`
- **Purpose**: Trains the behavioral anomaly detection model.
- **Library/Framework**: TensorFlow, Keras
- **Dataset**: Custom behavioral interaction dataset (simulated)
- **Output**: Exports a TensorFlow Lite model (`behavior_model.tflite`) that runs locally on the Flutter mobile app.

### 3. `XGBoost_Baseline.ipynb`
- **Purpose**: Trains a baseline XGBoost classifier for comparison against the GNN approach.
- **Library/Framework**: scikit-learn, XGBoost
- **Dataset**: BankSim
- **Output**: Generates a pickled model (`fraud_detection_model.pkl`) used by the legacy v1 server (`fraud-detection-server/app.py`).

## Usage
To run these notebooks, ensure you have Jupyter installed along with the respective ML frameworks. Note that the datasets are required and must be downloaded separately as they are excluded from version control due to file size limits.
