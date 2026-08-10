# GNN Fraud Detection Server

This is the main production server for the Beyond Rules banking fraud detection system. It uses a Heterogeneous Graph Neural Network (GNN) and a PostgreSQL database to assess the fraud probability of bank transactions.

## Overview
Unlike the legacy XGBoost server, this backend analyzes the relationships between customers and merchants by querying a Neo4j graph database. The GNN takes the transaction subgraph, scales the features using pre-trained scalers (`artifacts-final/`), and returns a fraud probability.

It also acts as the central API for the mobile application and admin dashboard, providing endpoints for payments, transaction logs, customer balances, and behavioral biometrics logging.

## Setup Instructions

1. **Environment Configuration**
   Copy `.env.example` to `.env` and fill in your PostgreSQL and Neo4j credentials.

2. **Database Setup**
   Ensure PostgreSQL is running and you have created a database (e.g., `logdb`).
   Ensure Neo4j is running.

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the Server**
   ```bash
   python app2.py
   ```
   The server will start on `http://localhost:8000`.

## Key Endpoints
- `POST /process_payment`: Core endpoint for processing a transaction and calculating the Fusion Score.
- `GET /admin/pending_transactions`: Retrieves transactions flagged for review.
- `POST /admin/review_transaction`: Approves or rejects a flagged transaction.
- `POST /behavioral/log`: Stores raw behavioral biometrics data from the mobile app.
- `GET /customers/{id}`: Retrieves a customer's current balance and details.
