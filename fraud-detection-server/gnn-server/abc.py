import pandas as pd
import tqdm
import dgl
from neo4j import GraphDatabase
import os

# Wait 60 seconds before connecting using these details, or login to https://console.neo4j.io to validate the Aura Instance is available
NEO4J_URI="neo4j+s://87925e12.databases.neo4j.io"
NEO4J_USERNAME="neo4j"
NEO4J_PASSWORD="RJ3pxRal-iXDVZ1XpfXQ2b6pPP9wy9GEiE1bqupNnS8"
NEO4J_DATABASE="neo4j"
AURA_INSTANCEID="87925e12"
AURA_INSTANCENAME="Instance01"
CSV_PATH = "GNN/bs140513_032310.csv"
SEED = 42
BATCH = 5000

driver = None  # Initialize driver to None
try:
    driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USERNAME, NEO4J_PASSWORD))

    constraint_cypher = """
    CREATE CONSTRAINT IF NOT EXISTS FOR (c:Customer) REQUIRE c.id IS UNIQUE;
    CREATE CONSTRAINT IF NOT EXISTS FOR (m:Merchant) REQUIRE m.id IS UNIQUE;
    CREATE CONSTRAINT IF NOT EXISTS FOR (t:Transaction) REQUIRE t.id IS UNIQUE;
    """

    with driver.session(database=NEO4J_DATABASE) as session:
        for stmt in constraint_cypher.strip().split(";"):
            stmt = stmt.strip()
            if stmt:
                session.run(stmt)
    print("Constraints created successfully.")
                
    df = pd.read_csv(CSV_PATH, low_memory=False)
    if 'inr_amount' not in df.columns and 'amount' in df.columns:
        df['inr_amount'] = df['amount']
    df['tx_uid'] = df.index  # Unique transaction ID

    # Optional: clean quotes if CSV has quoted IDs
    df['customer'] = df['customer'].str.strip("'")
    df['merchant'] = df['merchant'].str.strip("'")

    cypher = """
    UNWIND $rows AS r
    MERGE (c:Customer {id: r.customer})
      ON CREATE SET c.age = toInteger(r.age), c.gender = r.gender
    MERGE (m:Merchant {id: r.merchant})
      ON CREATE SET m.category = r.category
    CREATE (t:Transaction {
        id: r.tx_uid,
        amount: toFloat(r.inr_amount),
        step: toInteger(r.step),
        fraud: toInteger(r.fraud)
    })
    MERGE (c)-[:MAKES]->(t)
    MERGE (m)-[:RECEIVES]->(t);
    """

    with driver.session(database=NEO4J_DATABASE) as session:
        for start in tqdm.tqdm(range(0, len(df), BATCH), desc="Inserting data"):
            batch = df.iloc[start:start + BATCH].to_dict("records")
            session.run(cypher, rows=batch)

    print("BankSim data loaded into Neo4j successfully!!!")

finally:
    if driver:
        driver.close()
