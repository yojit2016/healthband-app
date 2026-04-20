# Health Band App

A real-time health monitoring Android application built with Flutter that continuously tracks vital signs and detects emergency conditions with instant alerts.

## Overview

Health Band App is a comprehensive health monitoring solution designed to provide continuous vital sign tracking with intelligent emergency detection. The app fetches health metrics every 5 seconds, maintains medication records, manages emergency contacts, and delivers timely notifications to keep users informed about their health status.

### Key Highlights

- **Real-Time Monitoring**: Continuous tracking of heart rate and SpO2 levels
- **Intelligent Alerts**: Multi-channel emergency notifications (visual, audio, and push notifications)
- **Medication Management**: Track medications with reminder functionality
- **Offline Support**: Graceful fallback with mock data when offline
- **Dark Medical Theme**: Eye-friendly UI optimized for health applications

## Features

### Health Monitoring
- Real-time heart rate tracking
- SpO2 (blood oxygen saturation) monitoring
- API polling every 5 seconds for fresh data
- Live data visualization with charts
- Historical health data tracking

### Emergency Detection
- Dual-layer detection system (API-based + threshold-based)
- Global full-screen emergency alert overlay
- Emergency alert sound with device vibration
- Immediate notification dispatch
- Emergency state management

### Medication Management
- Complete medication tracking system
- Mark medications as taken
- Optional reminder notifications
- Medication history logs
- Easy-to-use medication interface

### Additional Modules
- **Contacts**: Manage emergency contacts
- **Notifications**: View all health and emergency notifications
- **Pull-to-Refresh**: Available across all screens for manual data refresh

### Connectivity
- Offline-first architecture with mock data fallback
- Automatic data synchronization when online
- Robust error handling for network failures

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter |
| State Management | Riverpod |
| Networking | Dio |
| Local Storage | Hive |
| Data Visualization | fl_chart |
| Notifications | flutter_local_notifications |
| Background Tasks | flutter_foreground_task |

## Architecture

The application follows a clean, layered architecture pattern:

```
API Layer
    ↓
Service Layer (Business Logic)
    ↓
Riverpod Providers (State Management)
    ↓
UI Layer (Widgets & Screens)
```

### API Endpoints

The app integrates with backend endpoints for:

- **Health Data**: Real-time vital signs (heart rate, SpO2)
- **Emergency Events**: Emergency detection and status updates
- **Medications**: Medication list and tracking
- **Contacts**: Emergency contact management
- **Notifications**: Health alerts and notifications

## Getting Started

### Prerequisites

- Flutter SDK (version 3.0 or higher)
- Android SDK (API level 21 or higher)
- Dart 3.0 or higher

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd health-band-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Build APK

To generate a release APK:

```bash
flutter build apk --release
```

The APK will be available at `build/app/outputs/flutter-app.apk`

## Demo

### Credentials

Use the following credentials to test the application:

- **Email**: user@test.com
- **Password**: password123

### Demo Flow

1. **Login**: Enter demo credentials to access the app
2. **Dashboard**: View live health data with real-time updates
3. **Emergency Alert**: Trigger an emergency condition to see the full-screen alert overlay
4. **Medication Tracking**: Navigate to medications and mark a dose as taken
5. **Notifications**: View all historical notifications and alerts

## Screenshots

| Dashboard | Emergency Alert |
|-----------|-----------------|
| ![Dashboard](/screenshots/dashboard.png) | ![Emergency](/screenshots/emergency.png) |

| Medications | Notifications |
|------------|----------------|
| ![Medications](/screenshots/medications.png) | ![Notifications](/screenshots/notifications.png) |

## Project Structure

```
lib/
├── models/              # Data models
├── services/            # API and business logic services
├── providers/           # Riverpod state management
├── screens/             # UI screens and pages
├── widgets/             # Reusable widgets
├── utils/               # Helper functions and constants
├── config/              # App configuration
└── main.dart           # Entry point
```

## Configuration

Key configuration settings are located in the `config` directory:

- **API Base URL**: Backend server endpoint
- **Polling Interval**: Health data fetch frequency (default: 5 seconds)
- **Emergency Thresholds**: Heart rate and SpO2 alert limits
- **Notification Settings**: Alert sound and vibration preferences

## State Management with Riverpod

The app uses Riverpod for efficient state management:

- **Providers**: Manage health data, emergency status, medications, and notifications
- **Family Modifiers**: Support parameterized providers for dynamic queries
- **Auto Disposal**: Automatic cleanup of unused providers

Example provider usage:
```dart
final healthDataProvider = StreamProvider<HealthData>((ref) => healthService.getHealthData());
final emergencyStatusProvider = StateProvider<bool>((ref) => false);
```

## Data Persistence

Hive is used for local data storage:

- Offline health data cache
- Medication history
- User preferences
- Emergency contact information

## Notifications

The app implements multi-channel notifications:

- **Local Notifications**: Via `flutter_local_notifications`
- **Background Tasks**: Via `flutter_foreground_task`
- **Emergency Alerts**: Full-screen overlay with audio and haptic feedback

## Error Handling

Robust error handling includes:

- Network failure graceful degradation
- Invalid health metric validation
- Offline mode with mock data fallback
- User-friendly error messages

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes (`git commit -m 'Add amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request

## Troubleshooting

### App crashes on startup
- Ensure all dependencies are properly installed: `flutter pub get`
- Clean build files: `flutter clean`
- Rebuild the app: `flutter run`

### No health data appears
- Check that your device has internet connectivity
- Verify API endpoints are correct in configuration
- Try pulling to refresh on the dashboard

### Emergency alerts not triggering
- Ensure app permissions are granted (notification, location)
- Check that the device volume is not muted
- Verify emergency threshold settings

### Notifications not working
- Verify `flutter_local_notifications` permissions
- Check notification settings in device settings
- Ensure app is not restricted in battery optimization

## Performance Optimization

- Efficient state management with Riverpod
- Lazy loading of data with pagination
- Image caching for faster rendering
- Hive for optimized local data queries

## Security Considerations

- Secure storage of sensitive data (Hive with encryption)
- API request validation
- Secure transmission of health data
- User authentication via backend

## Known Limitations

- Emergency alerts require app to be running (for real-time detection)
- Background health monitoring dependent on `flutter_foreground_task`
- API polling frequency impacts battery consumption

## Future Enhancements

- Wearable device integration
- Machine learning-based anomaly detection
- Advanced health analytics and reports
- Telemedicine integration
- Multi-language support
- Cloud sync capability

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Yojit Pahwa**

## Support

For issues, bug reports, or feature requests, please open an issue on the project repository.

## Acknowledgments

- Flutter community for excellent documentation and packages
- All contributors who have helped improve this project
- Backend API team for reliable health data services

---

**Note**: This is a demonstration application. For production use in actual health monitoring, ensure compliance with medical device regulations and HIPAA guidelines.
