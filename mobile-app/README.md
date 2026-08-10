# Mobile App — Beyond Rules

The mobile client for the Beyond Rules banking fraud detection system.

## Overview
This Flutter application provides a mock banking interface that seamlessly integrates on-device behavioral biometrics and talks to the central fraud detection server. It captures session biometrics (such as tap duration, swipe speed, and screen dwell times) and generates a behavioral anomaly score using a TensorFlow Lite (TFLite) model running directly on the device.

## Features
- **On-Device TFLite Inference**: Generates a behavioral anomaly score locally to ensure privacy and low latency.
- **Behavioral Data Collection**: Captures typing cadence, tap positions, swipe vectors, and screen transitions.
- **Dynamic Configuration**: Connects to the FastAPI backend dynamically (configurable via Settings).
- **Payment Interface**: A clean, modern UI for initiating transactions, reviewing past payments, and managing cards.
- **Real-Time Fraud Feedback**: Visualizes the fusion score returned by the server.

## Setup Instructions

### Prerequisites
- Flutter SDK 3.8+
- Android Studio or Xcode

### Installation
1. Navigate to the `mobile-app` directory.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

### Configuration
Update the backend server IP in the app's Settings page or by modifying `lib/utils/constants.dart`.

## Technical Details
- **Framework**: Flutter
- **Key Packages**: `tflite_flutter`, `provider`, `fl_chart`, `http`
- **Model Path**: `assets/behavior_model.tflite`
