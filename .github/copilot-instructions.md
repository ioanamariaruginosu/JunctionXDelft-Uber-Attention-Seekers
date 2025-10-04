# Copilot Instructions for Uber Co-Pilot (Flutter/Dart)

## Project Overview
This is a production-ready Flutter app for Uber drivers, featuring an AI assistant (Atlas) that provides real-time insights, earnings optimization, and wellness support. The architecture follows MVVM with services, and is modular for multi-platform deployment (iOS, Android, Web).

## Key Architecture & Patterns
- **MVVM Structure**: 
  - `lib/models/`: Data models (user, trip, earnings, notification)
  - `lib/services/`: Business logic and API/service layers (Atlas AI, Auth, Notifications, Mock Data)
  - `lib/screens/`: UI screens (dashboard, auth, stats, settings)
  - `lib/widgets/`: Reusable UI components (Atlas orb, chat, popups)
  - `lib/utils/`: Shared utilities (theme, constants, validators)
- **State Management**: Uses Provider for dependency injection and state.
- **Navigation**: Go Router for screen transitions.
- **Charts/Animations**: FL Chart for stats, Lottie/custom for UI effects.
- **Demo Mode**: Mock data and auto-generated events for testing features without backend.

## Developer Workflows
- **Install dependencies**: `flutter pub get`
- **Run app**:
  - Web: `flutter run -d chrome`
  - Android: `flutter run -d android`
  - iOS: `flutter run -d ios`
- **Build for production**:
  - Web: `flutter build web --release`
  - Android: `flutter build apk --release` or `flutter build appbundle --release`
  - iOS: `flutter build ios --release`
- **Troubleshooting**:
  - Clean cache: `flutter clean; flutter pub cache repair; flutter pub get`
  - Diagnose issues: `flutter doctor -v`

## Project-Specific Conventions
- **Atlas AI logic** is centralized in `lib/services/atlas_ai_service.dart` and UI in `lib/widgets/atlas_widget.dart`.
- **Mock/demo data** is managed in `lib/services/mock_data_service.dart`.
- **Notification system** uses `lib/widgets/popup_system.dart` and `lib/services/notification_service.dart`.
- **Theme switching** and UI mode logic in `lib/utils/theme.dart` and `lib/screens/settings_page.dart`.
- **Earnings and trip analytics** are visualized using FL Chart in `lib/screens/stats_page.dart`.
- **Authentication** is handled in `lib/screens/auth_page.dart` and `lib/services/auth_service.dart`.

## Integration Points
- **No backend required for demo mode**; all data is simulated.
- **External packages**: Provider, Go Router, FL Chart, Lottie (see `pubspec.yaml`).
- **Platform-specific code**: Android/iOS/web folders for native integration.

## Example Patterns
- **Service usage**:
  ```dart
  final atlasService = Provider.of<AtlasAIService>(context);
  atlasService.getInsights(trip);
  ```
- **Theme switching**:
  ```dart
  ThemeMode mode = ThemeMode.system; // or .dark/.light
  ```
- **Mock trip generation**:
  ```dart
  MockDataService().generateTripRequest();
  ```

## Key Files/Directories
- `lib/main.dart`: App entry point
- `lib/models/`: Data models
- `lib/services/`: Business logic/services
- `lib/screens/`: UI screens
- `lib/widgets/`: Atlas orb, chat, popups
- `lib/utils/`: Theme, constants, validators
- `pubspec.yaml`: Dependencies

## Testing
- Widget tests in `test/widget_test.dart` (expand as needed)

---
**For questions, see README.md or open an issue.**
