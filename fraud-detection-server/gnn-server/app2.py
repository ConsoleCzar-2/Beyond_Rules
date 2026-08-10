from fastapi import FastAPI, HTTPException, Depends
import logging
from contextlib import asynccontextmanager
import uvicorn
import pandas as pd
import numpy as np
import torch
import dgl
from sklearn.preprocessing import StandardScaler
from torch import nn
from dgl.nn import HeteroGraphConv, GATConv
from neo4j import GraphDatabase, Driver
import pickle
import os
from pydantic import BaseModel
import psycopg2
from psycopg2 import sql, pool
import uuid
from datetime import datetime
import warnings
import psycopg2.extras
from typing import Dict, List, Optional

psycopg2.extras.register_uuid()

warnings.filterwarnings("ignore")

# --- Configuration ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- Pydantic Models ---
class TransactionInput(BaseModel):
    customer_id: str
    merchant_id: str
    amount: float
    tflite_score: float

class AdminReviewInput(BaseModel):
    id: uuid.UUID
    action: str # 'approve' or 'reject'

class UserActionInput(BaseModel):
    id: uuid.UUID
    action: str # 'confirm' or 'cancel'

class BalanceUpdate(BaseModel):
    amount: float
    type: str  # 'topup', 'debit', 'credit'
    description: str = None

class InternalTransactionRequest(BaseModel):
    source_id: str = None  # Optional for topups
    destination_id: str
    amount: float
    description: str = None
    transaction_type: str  # 'topup', 'transfer'

class BehavioralDataInput(BaseModel):
    id: str
    customer_id: str
    transaction_id: str
    session_id: str
    behavioral_features: List[float]
    screen_dwell_times: Optional[Dict[str, float]] = None
    total_taps: Optional[int] = None
    total_swipes: Optional[int] = None
    screen_transitions: Optional[int] = None
    session_duration: Optional[float] = None
    timestamp: Optional[str] = None

# --- Environment Configuration ---
NEO_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO_USER = os.getenv("NEO4J_USER", "neo4j")
NEO_PASSWORD = os.getenv("NEO4J_PASSWORD", "ABCD@1234")
SAVE_DIR = "artifacts-final"
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

POSTGRES_USER = os.getenv("POSTGRES_USER", "postgres")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "root")
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "localhost")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
LOG_DB_NAME = "logdb"

# --- Fraud Prediction Thresholds ---
PENDING_THRESHOLD = 0.40

# --- Global Dictionaries ---
data_artifacts = {}
ml_models = {}
db_pool = None
neo4j_driver = None

# --- Database Helper Functions ---
def get_db_conn():
    """Gets a connection from the pool for FastAPI's dependency injection."""
    if db_pool is None:
        raise HTTPException(status_code=500, detail="Database connection pool not initialized.")
    conn = None
    try:
        conn = db_pool.getconn()
        yield conn
    finally:
        if conn:
            db_pool.putconn(conn)

# --- ML Model and Prediction ---
class FraudGNN(nn.Module):
    def __init__(self, in_dims, hidden_dim=64, num_heads=2, num_layers=3, dropout=0.2):
        super().__init__()
        self.input_proj = nn.ModuleDict({ntype: nn.Linear(in_dim, hidden_dim) for ntype, in_dim in in_dims.items()})
        self.convs = nn.ModuleList()
        self.norms = nn.ModuleList()
        for _ in range(num_layers):
            self.convs.append(HeteroGraphConv({
                etype: GATConv(hidden_dim, hidden_dim // num_heads, num_heads)
                for etype in [('customer', 'MAKES', 'transaction'), ('merchant', 'RECEIVES', 'transaction'),
                              ('transaction', 'MAKES_BY', 'customer'), ('transaction', 'RECEIVES_BY', 'merchant')]
            }, aggregate='mean'))
            self.norms.append(nn.ModuleDict({ntype: nn.LayerNorm(hidden_dim) for ntype in ['customer', 'merchant', 'transaction']}))
        self.classifier = nn.Linear(hidden_dim, 2)
        self.dropout = nn.Dropout(dropout)

    def forward(self, g, inputs):
        h = {ntype: torch.relu(self.input_proj[ntype](feat)) for ntype, feat in inputs.items()}
        for conv, norm in zip(self.convs, self.norms):
            h_new = conv(g, h)
            h = {ntype: norm[ntype](h_new[ntype].view(h[ntype].shape) + h[ntype]) for ntype in h_new}
            h = {k: self.dropout(torch.relu(v)) for k, v in h.items()}
        return self.classifier(h["transaction"])

def predict_fraud(customer_id: str, merchant_id: str, amount: float):
    query = """
    MATCH (c:Customer {id: $cid})-[:MAKES]->(t:Transaction)<-[:RECEIVES]-(m:Merchant {id: $mid})
    RETURN count(t) AS cust_txn_count,
           avg(t.amount) AS cust_avg_amount,
           count(*) AS merch_txn_count,
           avg(t.amount) AS merch_avg_amount,
           avg(t.fraud) AS merch_fraud_rate
    """
    with neo4j_driver.session() as session:
        record = session.run(query, cid=customer_id, mid=merchant_id).single()

    if record is None or record["cust_txn_count"] is None:
        print(f"Cold-start for {customer_id} or {merchant_id} — using fallback values.")
        record = data_artifacts["global_defaults"]
    else:
        record = dict(record)
        for key in data_artifacts["global_defaults"]:
            if record[key] is None:
                record[key] = data_artifacts["global_defaults"][key]

    cust_feat_raw = np.array([[record["cust_txn_count"], record["cust_avg_amount"]]], dtype=np.float32)
    merch_feat_raw = np.array([[record["merch_txn_count"], record["merch_avg_amount"], record["merch_fraud_rate"]]], dtype=np.float32)
    tx_feat_raw = np.array([[amount]], dtype=np.float32)

    # Create a new heterogeneous graph directly
    g = dgl.heterograph({
        ("customer", "MAKES", "transaction"): ([0], [0]),
        ("merchant", "RECEIVES", "transaction"): ([0], [0]),
        ("transaction", "MAKES_BY", "customer"): ([0], [0]),
        ("transaction", "RECEIVES_BY", "merchant"): ([0], [0])
    })
    
    g.nodes["customer"].data["x"] = torch.tensor(data_artifacts["cust_scaler"].transform(cust_feat_raw), dtype=torch.float32)
    g.nodes["merchant"].data["x"] = torch.tensor(data_artifacts["merch_scaler"].transform(merch_feat_raw), dtype=torch.float32)
    g.nodes["transaction"].data["x"] = torch.tensor(data_artifacts["tx_scaler"].transform(tx_feat_raw), dtype=torch.float32)

    g = g.to(DEVICE)
    x_dict = {ntype: g.nodes[ntype].data["x"] for ntype in g.ntypes}

    with torch.no_grad():
        logits = ml_models["gnn"](g, x_dict)
        prob = torch.softmax(logits, dim=1)[0][1].item()
        print(f"Real-Time Fraud Probability: {prob:.4f}")
        return prob

def get_merchant_category(merchant_id: str) -> str:
    """
    Fetch merchant category from Neo4j GraphDB
    
    Args:
        merchant_id (str): The merchant ID to lookup
        
    Returns:
        str: The merchant category or 'unknown' if not found
    """
    query = """
    MATCH (m:Merchant {id: $merchant_id})
    RETURN m.category AS category
    """
    try:
        with neo4j_driver.session() as session:
            result = session.run(query, merchant_id=merchant_id)
            record = result.single()
            if record and record["category"]:
                logger.info(f"Found category '{record['category']}' for merchant {merchant_id}")
                return record["category"]
            else:
                logger.warning(f"No category found for merchant {merchant_id}, using 'unknown'")
                return "unknown"
    except Exception as e:
        logger.error(f"Error fetching merchant category for {merchant_id}: {e}")
        return "unknown"

# --- FastAPI Lifespan ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    global db_pool, neo4j_driver
    # Startup
    logger.info("Starting up application...")
    db_pool = psycopg2.pool.SimpleConnectionPool(1, 10, dbname=LOG_DB_NAME, user=POSTGRES_USER, password=POSTGRES_PASSWORD, host=POSTGRES_HOST, port=POSTGRES_PORT)
    
    conn = None
    try:
        conn = db_pool.getconn()
    finally:
        if conn:
            db_pool.putconn(conn)
    
    neo4j_driver = GraphDatabase.driver(NEO_URI, auth=(NEO_USER, NEO_PASSWORD))
    
    for f_name in ['cust_scaler.pkl', 'merch_scaler.pkl', 'tx_scaler.pkl', 'global_defaults.pkl', 'in_dims.pkl']:
        with open(os.path.join(SAVE_DIR, f_name), 'rb') as f:
            data_artifacts[f_name.split('.')[0]] = pickle.load(f)
            
    ml_models["gnn"] = FraudGNN(data_artifacts["in_dims"])
    ml_models["gnn"].load_state_dict(torch.load(f"{SAVE_DIR}/fraud_gnn.pt", map_location=DEVICE))
    ml_models["gnn"].eval().to(DEVICE)
    logger.info("Startup complete.")
    yield
    # Shutdown
    logger.info("Shutting down application...")
    if db_pool: db_pool.closeall()
    if neo4j_driver: neo4j_driver.close()
    logger.info("Shutdown complete.")

app = FastAPI(lifespan=lifespan, title="Fraud Detection API v3", version="3.0.0")

# --- API Endpoints ---
@app.post("/process_payment")
async def process_payment_endpoint(transaction: TransactionInput, conn=Depends(get_db_conn)):
    gnn_prob = predict_fraud(transaction.customer_id, transaction.merchant_id, transaction.amount)
    tflite_prob = 1 - transaction.tflite_score

    prob = sum([gnn_prob, tflite_prob]) / 2.0

    status = "pending" if prob >= PENDING_THRESHOLD else "paid"
    
    # Fetch merchant category from Neo4j GraphDB
    merchant_category = get_merchant_category(transaction.merchant_id)
    
    log_details = {
        "id": uuid.uuid4(), 
        "customer_id": transaction.customer_id, 
        "merchant_id": transaction.merchant_id,
        "merch_category": merchant_category,
        "amount": transaction.amount, 
        "fraud_probability": prob,
        "status": status, 
        "timestamp": datetime.now()
    }

    with conn.cursor() as cur:
        cur.execute(
            """INSERT INTO transaction_logs (id, customer_id, merchant_id, merch_category, amount, fraud_probability, status, timestamp) 
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            tuple(log_details.values())
        )

        if status == "paid":
            # Update customer balance if transaction is successful
            with conn.cursor() as cur:
                cur.execute(
                    """UPDATE customers SET balance = balance - %s, updated_at = %s WHERE id = %s""",
                    (transaction.amount, log_details["timestamp"], transaction.customer_id)
                )
        conn.commit()
    
    # Return transaction_id in the response
    log_details["transaction_id"] = str(log_details["id"])
    return log_details

@app.get("/admin/stats")
async def get_admin_stats(conn=Depends(get_db_conn)):
    with conn.cursor() as cur:
        cur.execute("SELECT SUM(amount) FROM transaction_logs WHERE status = 'paid'")
        total_volume = cur.fetchone()[0] or 0
        cur.execute("SELECT COUNT(*) FROM transaction_logs WHERE status = 'paid'")
        successful_txns = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM transaction_logs WHERE status = 'pending'")
        pending_reviews = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM transaction_logs")
        total_logs = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM transaction_logs WHERE status = 'fraud'")
        fraud_logs = cur.fetchone()[0]
        fraud_rate = (fraud_logs / total_logs) if total_logs > 0 else 0
    return {
        "total_transaction_volume": round(float(total_volume), 2),
        "successful_transactions": successful_txns,
        "pending_admin_reviews": pending_reviews,
        "overall_fraud_rate": round(fraud_rate * 100, 2)
    }

@app.get("/admin/pending_transactions")
async def get_pending_transactions(conn=Depends(get_db_conn)):
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM transaction_logs WHERE status = 'pending' ORDER BY timestamp DESC")
        rows = cur.fetchall()
        columns = [desc[0] for desc in cur.description]
        return [dict(zip(columns, row)) for row in rows]

@app.post("/admin/review_transaction")
async def review_transaction(review: AdminReviewInput, conn=Depends(get_db_conn)):
    new_status = 'awaiting-user-confirmation' if review.action == 'approve' else 'fraud'
    # reason = "Transaction approved by admin." if review.action == 'approve' else "Transaction rejected by admin as fraudulent."
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE transaction_logs SET status = %s WHERE id = %s AND status = 'pending'",
            (new_status, review.id)
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Transaction not found or not in pending state.")
    conn.commit()
    return {"message": f"Transaction {review.id} has been {review.action}d."}

@app.post("/transactions/user_action")
async def user_transaction_action(user_action: UserActionInput, conn=Depends(get_db_conn)):
    new_status = 'paid' if user_action.action == 'confirm' else 'cancelled'
    # reason = "Transaction confirmed by user." if user_action.action == 'confirm' else "Transaction cancelled by user."
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE transaction_logs SET status = %s WHERE id = %s AND status = 'awaiting-user-confirmation'",
            (new_status, user_action.id)
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Transaction not found or not awaiting user action.")

    if new_status == 'paid':
        # Update customer balance if transaction is confirmed
        with conn.cursor() as cur:
            cur.execute(
                """UPDATE customers SET balance = balance + (SELECT amount FROM transaction_logs WHERE id = %s), 
                   updated_at = NOW() WHERE id = (SELECT customer_id FROM transaction_logs WHERE id = %s)""",
                (user_action.id, user_action.id)
            )
            if cur.rowcount == 0:
                raise HTTPException(status_code=404, detail="Customer not found for the transaction.")
    conn.commit()

    return {"message": "User action recorded."}

@app.get("/transactions/logs/{customer_id}")
async def get_transaction_logs(customer_id: str, conn=Depends(get_db_conn)):
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM transaction_logs WHERE customer_id = %s ORDER BY timestamp DESC", (customer_id,))
        rows = cur.fetchall()
        columns = [desc[0] for desc in cur.description]
        return [dict(zip(columns, row)) for row in rows]

@app.post("/behavioral/log")
async def log_behavioral_data(behavioral_data: BehavioralDataInput, conn=Depends(get_db_conn)):
    try:
        # Parse timestamp if provided, otherwise use current time
        timestamp = datetime.fromisoformat(behavioral_data.timestamp.replace('Z', '+00:00')) if behavioral_data.timestamp else datetime.now()
        
        with conn.cursor() as cur:
            cur.execute(
                """INSERT INTO behavioral_logs 
                   (id, customer_id, transaction_id, session_id, behavioral_features, 
                    screen_dwell_times, total_taps, total_swipes, screen_transitions, 
                    session_duration, timestamp)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                (
                    behavioral_data.id,
                    behavioral_data.customer_id,
                    behavioral_data.transaction_id,
                    behavioral_data.session_id,
                    psycopg2.extras.Json(behavioral_data.behavioral_features),
                    psycopg2.extras.Json(behavioral_data.screen_dwell_times) if behavioral_data.screen_dwell_times else None,
                    behavioral_data.total_taps,
                    behavioral_data.total_swipes,
                    behavioral_data.screen_transitions,
                    behavioral_data.session_duration,
                    timestamp
                )
            )
        conn.commit()
        
        logger.info(f"Behavioral data logged for customer {behavioral_data.customer_id}, transaction {behavioral_data.transaction_id}")
        
        return {
            "message": "Behavioral data logged successfully",
            "customer_id": behavioral_data.customer_id,
            "transaction_id": behavioral_data.transaction_id,
            "session_id": behavioral_data.session_id,
            "timestamp": timestamp.isoformat()
        }
        
    except Exception as e:
        conn.rollback()
        logger.error(f"Error logging behavioral data: {e}")
        raise HTTPException(status_code=500, detail=f"Error logging behavioral data: {str(e)}")

@app.get("/health")
async def health_check():
    try:
        # Check Neo4j connection
        with neo4j_driver.session() as session:
            session.run("RETURN 1")
        
        # Check PostgreSQL connection
        conn = db_pool.getconn()
        if conn:
            db_pool.putconn(conn)
        
        return {"status": "healthy"}
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=500, detail="Service is unhealthy.")

# 1. Get customer details
@app.get("/customers/{customer_id}")
async def get_customer_details(customer_id: str, conn=Depends(get_db_conn)):
    try:
        with conn.cursor() as cur:
            # Check if customer exists in the balance table
            cur.execute(
                """SELECT balance FROM customers WHERE id = %s""",
                (customer_id,)
            )
            result = cur.fetchone()
            
            if not result:
                # If customer doesn't exist in our system yet
                return {
                    "id": customer_id,
                    "name": "",
                    "email": "",
                    "balance": 0.0,
                    "created_at": ""
                }
            
            # Get transaction history summary
            cur.execute(
                """SELECT COUNT(*), SUM(amount) FROM transaction_logs 
                   WHERE customer_id = %s AND status = 'paid'""",
                (customer_id,)
            )
            txn_data = cur.fetchone()
            
            return {
                "id": customer_id,
                "balance": float(result[0]),
                "transaction_count": txn_data[0] or 0,
                "total_spent": float(txn_data[1] or 0),
                "last_updated": datetime.now().isoformat()
            }
    except Exception as e:
        logger.error(f"Error retrieving customer: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving customer details")

# 2. Update customer balance (for topups, transfers)
@app.post("/customers/{customer_id}/balance")
async def update_customer_balance(customer_id: str, transaction: BalanceUpdate, conn=Depends(get_db_conn)):
    try:
        # Use PostgreSQL to handle balance updates instead of Neo4j
        with conn.cursor() as cur:
            # First check if customer exists and get current balance
            cur.execute(
                """SELECT balance FROM customers WHERE id = %s""",
                (customer_id,)
            )
            customer = cur.fetchone()
            
            if not customer:
                # Create customer record if it doesn't exist
                current_balance = 10000.0
                cur.execute(
                    """INSERT INTO customers (id, name, balance, created_at, updated_at)
                       VALUES (%s,%s , %s,  %s, %s) RETURNING balance""",
                    (customer_id, f"Test User {customer_id}", current_balance, datetime.now(), datetime.now())
                )
            else:
                current_balance = customer[0]
            
            # Log the balance update request
            log_id = uuid.uuid4()

            new_balance = float(current_balance) + float(transaction.amount)

            cur.execute(
                """UPDATE customers SET balance = %s WHERE id = %s""",
                (new_balance, customer_id)
            )
            
        conn.commit()
        
        return {
            "customer_id": customer_id,
            "previous_balance": current_balance,
            "new_balance": new_balance,
            "transaction_id": str(log_id),
            "type": transaction.type,
            "amount": transaction.amount
        }
    except Exception as e:
        conn.rollback()
        logger.error(f"Error processing balance update: {e}")
        raise HTTPException(status_code=500, detail="Error processing balance update request")

# 3. Get transaction statistics for a customer
@app.get("/customers/{customer_id}/stats")
async def get_customer_stats(customer_id: str, conn=Depends(get_db_conn)):
    try:
        with conn.cursor() as cur:
            # Total spending
            cur.execute(
                """SELECT SUM(amount) FROM transaction_logs 
                   WHERE customer_id = %s AND status = 'paid'""", 
                (customer_id,)
            )
            total_spent = cur.fetchone()[0] or 0
            
            # Monthly totals (last 6 months)
            cur.execute(
                """SELECT 
                    DATE_TRUNC('month', timestamp) as month,
                    SUM(amount) as total
                   FROM transaction_logs
                   WHERE customer_id = %s AND status = 'paid'
                   AND timestamp > NOW() - INTERVAL '6 months'
                   GROUP BY DATE_TRUNC('month', timestamp)
                   ORDER BY month DESC""",
                (customer_id,)
            )
            monthly_totals = [{"month": row[0].strftime("%Y-%m"), "total": float(row[1])} 
                             for row in cur.fetchall()]
            
            # Merchant categories
            cur.execute(
                """SELECT 
                    merchant_id, 
                    COUNT(*) as transaction_count, 
                    SUM(amount) as total_amount
                   FROM transaction_logs
                   WHERE customer_id = %s AND status = 'paid'
                   GROUP BY merchant_id
                   ORDER BY total_amount DESC
                   LIMIT 5""",
                (customer_id,)
            )
            top_merchants = [{"merchant_id": row[0], "count": row[1], "amount": float(row[2])} 
                           for row in cur.fetchall()]
            
            return {
                "customer_id": customer_id,
                "total_spent": float(total_spent),
                "monthly_totals": monthly_totals,
                "top_merchants": top_merchants
            }
    except Exception as e:
        logger.error(f"Error retrieving customer stats: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving customer statistics")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
