# Admin Dashboard — Beyond Rules

A static web dashboard for bank administrators to review AI-flagged transactions.

## Overview
The Beyond Rules system flags suspicious transactions based on a Fusion Score (Graph Neural Network + Behavioral Biometrics). Transactions with a score ≥ 0.40 are routed to this dashboard for manual review. 

## Features
- **Key Statistics**: Monitor total transaction volume, success counts, pending reviews, and the overall fraud rate.
- **Pending Reviews Table**: Interface to quickly approve or reject flagged transactions.
- **Transaction Logs**: Filterable history of all processed transactions.
- **Analytics Charts**: Visualizations for score distributions, hourly volume, and model comparison (GNN vs Behavioral).
- **Live API Connection**: Can connect to a running FastAPI server or fall back to mock data.

## Setup Instructions

No build step or installation is required for the dashboard.

1. Navigate to the `admin-dashboard` directory.
2. Open `index.html` in any modern web browser.
3. (Optional) To connect to the live backend, enter the URL of the running `fraud-detection-server` (e.g., `http://localhost:8000`) in the sidebar's connection input and click the connect button.

## Technical Details
- **Tech Stack**: HTML5, CSS3, Vanilla JavaScript
- **Visualizations**: Chart.js
- **Styling**: Custom CSS matching the dark-mode aesthetic of the mobile application.
