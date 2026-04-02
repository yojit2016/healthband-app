# 🏥 Health Band Android App

A Flutter-based mobile application that simulates a real-time health monitoring system with emergency alert functionality.

## 📸 Screenshots

| Dashboard | Emergency Alert |
|----------|----------------|
| ![](screenshots/dashboard.png) | ![](screenshots/emergency.png) |

| Medications | Notifications |
|------------|--------------|
| ![](screenshots/medications.png) | ![](screenshots/notifications.png) |

*See [screenshots/README.md](screenshots/README.md) for instructions on adding images*

## 🚀 Features

- 🔐 **Authentication**
  - Simple login system using Hive storage

- 📊 **Real-Time Health Monitoring**
  - Live data fetching every 5 seconds using Dio
  - Displays:
    - Heart Rate (BPM)
    - SpO2 (Blood Oxygen)
  - Automatic fallback to mock data if API fails

- 🚨 **Emergency Alert System**
  - Triggered via:
    - API-based emergency events
    - Threshold-based detection (abnormal vitals)
  - Features:
    - Full-screen emergency overlay
    - Alarm sound (user-enabled)
    - High-priority notifications

- 💊 **Medication Tracking**
  - Mark medications as taken
  - Immediate UI updates
  - Pull-to-refresh functionality

- 👥 **Contacts & Notifications**
  - Emergency contacts management
  - Notification history
  - Pull-to-refresh on all lists

- 🔄 **Background Processing**
  - Uses foreground services for continuous monitoring

- 💾 **Alert History**
  - Stores recent emergency events locally using Hive
  - Displays last 10 alerts

## 🏗️ Architecture

API → Service → Provider → UI

## 🛠 Tech Stack

- Flutter
- Riverpod (State Management)
- Dio (Networking)
- Hive (Local Storage)
- fl_chart (Graphs)
- flutter_local_notifications
- flutter_foreground_task

## 📡 API Integration

- Health Data:
  https://health-band-server.vercel.app/api/v1/health-data

- Emergency Events:
  https://health-band-server.vercel.app/api/v1/emergency-events

## 🎯 Key Concepts

- Polling-based real-time data updates
- State-driven UI architecture
- Fault-tolerant data handling with mock fallback
- Local persistence using Hive

## 📱 Demo Flow

1. Login with test credentials
2. View live health metrics
3. Detect abnormal vitals
4. Trigger emergency alert
5. View alert history
6. Manage medications and contacts

## 🔑 Test Credentials

- Email: user@test.com
- Password: password123

## 📥 APK Download

[Download APK](#)

## 👨‍💻 Author

Yojit Pahwa

## ⚠️ Note

This is a demo application and uses simulated health data for demonstration purposes.
