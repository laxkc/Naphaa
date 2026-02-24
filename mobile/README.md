# Mobile

Flutter mobile app for the SME Digital platform.

## Requirements

- Flutter SDK (compatible with Dart `^3.7.0`)

## Setup

```bash
cd mobile
flutter pub get
```

## Run locally

```bash
cd mobile
flutter run
```

## Backend API

The app currently uses this local API base URL:

- `http://127.0.0.1:8000/api/v1`

If you run on a physical device/emulator, update the API URL in:

- `lib/core/config/app_config.dart`

## Useful commands

```bash
flutter test
flutter analyze
```
