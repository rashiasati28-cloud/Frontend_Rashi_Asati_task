# Security Alerts Dashboard

A Flutter Web dashboard for monitoring and resolving application security alerts, built for the Bugsmirror internship assessment.

## How to run

1. Ensure Flutter is installed and available in your environment.
2. Fetch the required dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application in Google Chrome:
   ```bash
   flutter run -d chrome
   ```
4. Run static code analysis:
   ```bash
   flutter analyze
   ```

> **Note**: To test the error screen, set `simulateError = true` in `lib/data/alert_repository.dart`.

### Flutter Version
```
Flutter 3.50.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision ae9b586f34 (5 days ago) • 2026-11-18 17:01:07 -0800
Engine • hash 51379e6df48ea8ee7205623b90fe66491cad8df3 (revision 4d35714800) (6 days ago) • 2026-11-18 01:50:07.000Z
Tools • Dart 3.14.0 • DevTools 2.61.0
```

## Project structure

- `lib/main.dart` - Application entry point, `MultiProvider` setup, and `GoRouter` declarative route definitions.
- `lib/constants/threat_names.dart` - `threatNameMap` mapping raw threat codes to human-readable names and fallback lookup helper.
- `lib/models/alert_enums.dart` - `Severity` (High, Medium, Low) and `AlertStatus` (Open, Resolved) enums with safe case-insensitive parsing.
- `lib/models/app_info.dart` - `AppInfo` model with ID, name, platform, and `displayName` getter formatted as "QuickPay (iOS)".
- `lib/models/alert_item.dart` - `AlertItem` model with defensive parsing for null/missing values, `copyWith` for resolution, and UTC date formatting.
- `lib/models/alert_data.dart` - Container model holding lists of `AppInfo` and `AlertItem` with safe lookup helpers.
- `lib/data/alert_repository.dart` - Repository that reads `assets/alerts.json` with an artificial 1s delay and a `simulateError` flag.
- `lib/state/alerts_provider.dart` - `ChangeNotifier` state manager holding loaded alerts, filter/sort state, 5-per-page pagination, and resolution logic.
- `lib/screens/dashboard_screen.dart` - Screen 1: Metric summary cards, monitored apps list with open alert counts, and navigation shortcuts.
- `lib/screens/alerts_screen.dart` - Screen 2: Filterable and sortable alert cards list with 5-per-page pagination and empty state handling.
- `lib/screens/alert_detail_screen.dart` - Screen 3: Full field inspection of an individual alert with confirmation dialog to resolve.
- `lib/widgets/severity_chip.dart` - Reusable chip component styled with severity-based theme colors (High: red, Medium: orange, Low: grey).
- `lib/widgets/summary_card.dart` - Reusable card displaying metric values, descriptive title, and accent icons.
- `lib/widgets/loading_view.dart` - Centered loading spinner with customizable status text.
- `lib/widgets/error_view.dart` - Friendly error state banner with a "Retry" button to trigger reload.
- `assets/alerts.json` - Original mock security alerts data (never modified).
- `pubspec.yaml` - Project specification containing only approved packages (`provider`, `go_router`, `intl`) and asset configuration.
- `test/widget_test.dart` - Unit tests verifying threat name mapping, enum parsing, data loading, expected metrics, resolution, and messy data handling.
- `web/` - Flutter Web entry and bootstrap files including `index.html`, `manifest.json`, and web app icons.

## What works and what does not

### What works:
- **Dashboard Overview**: Displays total alerts (14), open alerts (11), and high-severity open alerts (5).
- **Monitored Apps**: Lists apps with normalized platform indicators and live open alert badges (QuickPay Android: 6, QuickPay iOS: 3, ShopKart Android: 2).
- **Navigation & History**: Full browser back/forward button support using `go_router` route pushing (`/`, `/alerts`, `/alerts/:id`).
- **Alert Filtering & Sorting**: Filter by App, Severity (High, Medium, Low), and Status (Open, Resolved); sort by Newest first or Severity (High to Low).
- **Pagination**: 5 alerts per page with Previous/Next controls, "Page X of N" indicator, and automatic reset to Page 1 upon filter change.
- **Empty State**: Displays a clean "No alerts match these filters" message with a reset button when zero items match.
- **Messy Data Resilience**: Safely handles null `deviceModel` ("Unknown"), missing `osVersion` ("-"), unmapped threat codes (raw fallback), and mixed-case severity strings without crashing.
- **Date Conversion**: Converts UTC millisecond timestamps to local time formatted cleanly as `d MMM y, h:mm a`.
- **Live Alert Resolution**: Open alerts can be marked as resolved with an "Are you sure?" confirmation dialog. Status updates in-memory across all screens immediately with zero reload.
- **Error Simulation**: Toggling `simulateError = true` displays a friendly `ErrorView` with a functional `Retry` button.
- **Responsive Layout**: Fluid layout across 400px to 1280px widths with no overflow stripes.
- **Analysis**: Clean `flutter analyze` ("No issues found!").

### What does not work:
- Resolved alerts are kept in memory only, so a page reload brings them back to open.
- No bonus features (search, CSV, table layout, deep links beyond the three routes, extra unit tests).

## How AI helped

<!-- Placeholder: Write in your own words how AI helped you during the task -->

## Questions

### 1. Where does your app keep the list of alerts, and how does the Dashboard learn about a resolved alert?
The list of alerts is kept in memory inside the `AlertsProvider` class (`lib/state/alerts_provider.dart`) in `_data!.alerts`. When an alert is resolved on the Alert Detail screen, `resolveAlert()` updates its status to `AlertStatus.resolved` in that list and calls `notifyListeners()`. Because `DashboardScreen` and `AlertsScreen` both listen to this shared provider instance via `context.watch<AlertsProvider>()`, `notifyListeners()` immediately triggers a rebuild of the dashboard widgets, updating the open alert counts instantly with no page reload.

### 2. What would need to be changed to use a real API instead of the local JSON file?
Only `AlertRepository` (`lib/data/alert_repository.dart`) needs to change:
- Replace `rootBundle.loadString('assets/alerts.json')` with an HTTP GET request (e.g. using `package:http`) to fetch alerts from your backend endpoint.
- Add an API call in the repository (e.g. an HTTP PATCH or POST request) that notifies the backend when an alert is resolved in `resolveAlert()`.
The UI screens, router, widgets, and models would stay completely unchanged because they only interact with the provider and the repository interface.

## Video

https://drive.google.com/file/d/1BXswUcD4aP_p5JbqJ0KSvhkjN_w9lUaG/view?usp=drive_link
