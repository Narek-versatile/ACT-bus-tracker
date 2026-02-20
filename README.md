# Tracker Login (Telegram)
`tracker-login-tg` (formerly `bus_tracking_app`) is a Flutter-based real-time mobile GPS tracking application. This project has been fully reconfigured to feature a mock authenticated login system and streams live location payload explicitly to a Telegram Bot for real-timeline server simulation.

## Overview
This application demonstrates real-time authenticated location pushing using a background service. It acts exactly like a traditional mobile-to-backend infrastructure, but overrides network transmission to deliver fully formatted HTTP JSON payloads straight into a Telegram Chat for immediate observation and testing.

## Features
- **Mock Token Authentication**: Users enter a `Login` and `Password` to securely generate a mock JWT authentication token. 
- **Real-time Background Tracking**: Utilizes `flutter_background_service` to ping precise GPS coordinates every 10 seconds, regardless of whether the app is asleep or foregrounded.
- **Client-Server JSON Observation**: Converts all backend operations directly into stringified HTTP-like payloads (including mocked `Authorization: Bearer <token>` Headers) directly to a Telegram channel.

## Security & Secrets Management 
To prevent leaking sensitive API keys, the real Telegram IDs are hidden securely within `lib/secrets.dart` which is explicitly ignored by Git (`.gitignore`).

### Setting It Up (Required before compiling)
If you just cloned this repository, you must create the secure secrets file manually:
1. Navigate to the `lib/` directory inside your project.
2. Create a new file called `secrets.dart`.
3. Add the following structure, replacing the values with your actual Telegram bot data:
```dart
class Secrets {
  static const String telegramBotToken = 'YOUR_TELEGRAM_BOT_TOKEN_HERE';
  static const String telegramChatId = 'YOUR_TELEGRAM_CHAT_ID_HERE';
}
```
*(There is also a `lib/secrets_example.dart` included natively in the repository as a visual reference).*

## How It Works (Telegram Server Mock vs Real MVP)
### 1. The Login Phase
* **Client App**: Sends a mock login request with credentials.
* **Backend Expected**: Expected to validate against a database and generate real JWT secure tokens.
* **App Implementation**: Generates a simulated `mock_access_token`, saves it natively inside SharedPreferences, and alerts your Telegram bot of the login.

### 2. The Tracking Phase
* **Client App**: Pulls the GPS data and injects the stored `mock_access_token` into the header:
  `Authorization: Bearer mock_access_token_123456...`
* **Backend Expected**: The physical server validates the JWT header to securely identify the emitting driver.
* **App Implementation**: Because Telegram does not natively digest Authentication Headers, the Flutter app physically reconstructs the JSON `Header` + `Payload` into the text alert so you can visibly see what your actual backend database server *will* be ingesting.

## Publishing to GitHub Safely
If you've modified the app, you can seamlessly push the directory to GitHub. Because `lib/secrets.dart` is in the `.gitignore`, nothing secretive will ever leak to the internet!

Run these basic commands directly from your computer tracking terminal:
```bash
git init
git add .
git commit -m "Initialize secure tracker-login-tg"
```
Then, create an empty repository on GitHub and paste the commands they provide:
```bash
git remote add origin https://github.com/YourUsername/tracker-login-tg.git
git branch -M main
git push -u origin main
```
