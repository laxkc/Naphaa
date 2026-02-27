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
flutter run --dart-define=APP_ENV=dev
```

## Backend API

API base URL is loaded from environment JSON assets:

- `assets/env/dev.json`
- `assets/env/prod.json`

Select environment with:

```bash
flutter run --dart-define=APP_ENV=dev
flutter run --dart-define=APP_ENV=prod
```

## Useful commands

```bash
flutter test
flutter analyze
```
