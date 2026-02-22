# ACT Bus Tracker

`ACT-bus-tracker` is a Flutter-based real-time mobile GPS tracking application designed to verify driver credentials and stream live location payloads directly to the Matrix backend infrastructure.

## Overview

This application demonstrates real-time authenticated location pushing using a background service. It connects directly to the production Matrix server endpoints to deliver HTTP JSON payloads at regular intervals.

## Features

- **Token Authentication**: Users enter a `Login` and `Password` to securely generate and retrieve an authentication token directly from the Matrix backend (`/matrix/transport/mobile/token/`).
- **Real-time Background Tracking**: Utilizes `flutter_background_service` to ping precise GPS coordinates (`lat`, `lng`, `time`) to the backend (`/matrix/transport/location/`) every 10 seconds, regardless of whether the app is asleep or foregrounded.
- **Secure Token Headers**: The retrieved token is injected as an `X-API-KEY` header inside every location update HTTP request.

## Security & Secrets Management 

To prevent leaking sensitive API endpoints, the backend URLs are hidden securely within `lib/secrets.dart` which is explicitly ignored by Git (`.gitignore`).

### Setting It Up (Required before compiling)

If you just cloned this repository, you must create the secure secrets file manually:
1. Navigate to the `lib/` directory inside your project.
2. Create a new file called `secrets.dart`.
3. Add the following structure, replacing the values with your actual API URLs:

```dart
class Secrets {
  static const String tokenApiUrl = 'your backend URL here';
  static const String locationApiUrl = 'your backend URL here';
}
```

*(There is also a `lib/secrets_example.dart` included natively in the repository as a visual reference).*

## How It Works

### 1. The Login Phase
* **Client App**: Sends a `POST` request with the driver's `{'example': 'example'}`.
* **Backend Expected**: Validates credentials and returns a secure token.
* **App Implementation**: Extracts the token from the response, saves it natively inside `SharedPreferences`, and uses it to identify the specific driver in future requests.

### 2. The Tracking Phase
* **Client App**: Pulls the GPS data and formats it as `{"lat": value, "lng": value, "time": value}`.
* **App Implementation**: Sends a `POST` request every 10 seconds. Injects the stored token into the header:
  `X-API-KEY: <retrieved_token>`
* **Backend Expected**: The Physical Server validates the `X-API-KEY` header to securely identify the emitting driver and processes the updated location payload.

## APK Release

A pre-compiled production-ready Android APK is provided inside the `apk/` directory:
- `apk/bus_tracking_app.apk`

You can download it directly from the GitHub repository to install on your Android device.
