<div align="center">

# Beyond Rules

### Adaptive Fraud Detection for Banks

*A multi-layered AI system combining Graph Neural Networks, on-device behavioral biometrics, and signature verification to detect banking fraud in real-time.*

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.0+-EE4C2C?logo=pytorch)](https://pytorch.org)
[![Neo4j](https://img.shields.io/badge/Neo4j-5.x-008CC1?logo=neo4j)](https://neo4j.com)

**Team FunctionOverload** — UCO Bank Hackathon

[Wiki](https://github.com/ConsoleCzar-2/Beyond_Rules/wiki) · [Presentation](docs/Beyond_Rules_Presentation_v4.pdf)

</div>

---

## Overview

**Beyond Rules** is an adaptive fraud detection system for banks. It replaces rigid rule engines with a **multi-layered AI fusion approach** that analyses transactions at three levels simultaneously:
1. **On-Device TFLite Behavioral Model**: Detects anomalous user interaction patterns.
2. **Graph Neural Network (GNN)**: Analyzes transaction graph topology via Neo4j to find suspicious patterns.
3. **Fusion Scoring**: Averages the scores and flags high-risk transactions for human review.

This **dual-validation approach** significantly reduces false positives while catching sophisticated fraud that either model alone might miss.

---

## Quick Start

> **Important Configuration Note**: The placeholder `<YOUR_SERVER_IP>` is used in the Flutter client code (e.g., `settings_service.dart` and `signature_api_service.dart`) as well as the test notebooks. Before running the mobile app, signature app, or test notebooks, make sure to replace `<YOUR_SERVER_IP>` with the actual IP address of the machine hosting your FastAPI servers.

### 1. Clone & Run the GNN Server
```bash
git clone https://github.com/ConsoleCzar-2/Beyond_Rules.git
cd Beyond_Rules/fraud-detection-server/gnn-server

# Install dependencies and setup environment
pip install -r requirements.txt
cp .env.example .env

# Start the primary server
python app2.py
```
*The server will start on `http://localhost:8000`.*

### 2. Run the Mobile App
```bash
cd ../../mobile-app
flutter pub get
flutter run
```

### 3. Run the Signature Verification App
```bash
cd ../signature-verification
flutter pub get
flutter run
```
*(Note: To run the companion Signature FastAPI server, navigate to `signature-verification/fastapi_server` and run `python main.py`.)*

For detailed, step-by-step installation instructions for all components (including the Admin Dashboard), please see the [Setup & Installation Guide](https://github.com/ConsoleCzar-2/Beyond_Rules/wiki/Setup-Guide) on the wiki.

---

## Technical Documentation (Wiki)

All detailed technical explanations, setup instructions, and architecture diagrams are hosted on the Project Wiki.

- **[Home & Problem Statement](https://github.com/ConsoleCzar-2/Beyond_Rules/wiki)**: The overarching problem statement, our proposed Fusion Score solution, and how the layers interact.
- **[System Architecture & ML Models](https://github.com/ConsoleCzar-2/Beyond_Rules/wiki/Architecture)**: Deep dive into the transaction flows, Mermaid diagrams, Graph Neural Network schemas, TFLite behavioral features, and PostgreSQL database designs.
- **[Components Overview](https://github.com/ConsoleCzar-2/Beyond_Rules/wiki/Components)**: Breakdown of the monorepo structure, detailing the tech stack and purpose of each folder (mobile-app, servers, admin-dashboard, etc.).
- **[Setup & Installation Guide](https://github.com/ConsoleCzar-2/Beyond_Rules/wiki/Setup-Guide)**: Comprehensive, step-by-step instructions for running the GNN Server, Mobile App, Signature Verification system, and Admin Dashboard.
- **[API Reference](https://github.com/ConsoleCzar-2/Beyond_Rules/wiki/API-Reference)**: Complete documentation of the FastAPI endpoints, including request methods, sample payloads, and responses.

---

## Datasets

This project uses the **BankSim** synthetic banking dataset for training:

| Dataset | Description | Download |
|---------|-------------|----------|
| `BankSim-Updated-Processed_new.csv` | Processed BankSim with engineered features | [Google Drive Link](https://drive.google.com/file/d/12B9ACHJI-DSla2gGpUc4dEP4kKDKBTr-/view?usp=sharing) |
| `BankSim-Updated.csv` | Intermediate processed version | [Google Drive Link](https://drive.google.com/file/d/1MQ9y0IsRg3vvgghHVW4ng5u3tWgrPafD/view?usp=sharing) |
| `bs140513_032310.csv` | Original BankSim dataset | [Google Drive Link](https://drive.google.com/file/d/17S4nJBH91wdIKDCP4OelC-axUJ59nFr5/view?usp=sharing) |

> The CSV files are excluded from the repository due to size constraints. Download them from the links above and place them in the appropriate directories.

---

## Team

**Team FunctionOverload** — Indian Institute of Engineering Science and Technology, Shibpur

| Name | Role |
|------|------|
| **Abhirup Saha** | Team Lead, Architecture, Signature Verification |
| **Pritam Bag** | Mobile App Development, Demo, System Integration |
| **Swarnava Banerjee** | ML Engineering |
| **Yasharth Shukla** | Admin Dashboard, Analytics |

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

*Built for the UCO Bank Hackathon, 2025*

</div>