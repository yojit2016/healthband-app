# Health Band API Endpoints

Here are all the API endpoints discovered from the backend's Swagger documentation:

## Health Data
- **GET** `/api/v1/health-data` - Get the latest health data reading.
- **POST** `/api/v1/health-data` - Record new health data (pulse, oxygen).
- **GET** `/api/v1/health-data/summary` - Get health dashboard summary (includes averages, stats, device status).
- **GET** `/api/v1/health-data/insights` - Get health data insights with date/time filters.
- **GET** `/api/v1/health-data/heatmap/monthly` - Get monthly health data heatmap for dashboard charts.

## Emergency Events
- **GET** `/api/v1/emergency-events` - Get all emergency events (supports filtering).

## Emergency Contacts
- **GET** `/api/v1/emergency-contacts` - Get all emergency contacts.
- **POST** `/api/v1/emergency-contacts` - Add a new emergency contact.
- **PATCH** `/api/v1/emergency-contacts/{id}` - Edit an emergency contact.
- **DELETE** `/api/v1/emergency-contacts/{id}` - Remove an emergency contact.

## Medications
- **GET** `/api/v1/medications` - Get all medication schedules.
- **POST** `/api/v1/medications` - Add a new medication schedule.
- **PATCH** `/api/v1/medications/{id}` - Edit a medication schedule.
- **DELETE** `/api/v1/medications/{id}` - Deactivate a medication schedule.
- **PATCH** `/api/v1/medications/reminder/{id}/taken` - Mark a medication reminder as taken.
- **GET** `/api/v1/medications/medication-reminder` - Manually trigger the medication reminder scheduler.

## Notifications
- **GET** `/api/v1/notifications` - Get all notifications sent across all emergencies.
- **GET** `/api/v1/notifications/emergency/{id}` - Get all notifications for a specific emergency event.
