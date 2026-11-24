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
4. (Optional) Run static code analysis:
   ```bash
   flutter analyze
   ```

### Flutter Version
```
PS D:\frontend_Rashi_Asati> flutter --version
Flutter 3.50.1 • channel stable •
https://github.com/flutter/flutter.git
Framework • revision ae9b586f34 (5 days ago) • 2026-11-18 17:01:07
-0800
Engine • hash 51379e6df48ea8ee7205623b90fe66491cad8df3 (revision
4d35714800) (6 days ago) • 2026-11-18 01:50:07.000Z
Tools • Dart 3.14.0 • DevTools 2.61.0
```

## Project structure

- `lib/main.dart` - Application entry point, `MultiProvider` dependency injection, and `GoRouter` declarative route definitions.
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
test/widget_test.dart - basic test

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

### What does not:
- **Persistence**: Resolved alerts are updated in-memory for the duration of the browser session; changes are not written back to `assets/alerts.json` (per spec).
- **Bonus Features**: Search bar, CSV export, table view, and deep linking beyond spec routes were intentionally excluded to respect timed constraints.

## How AI helped

<!-- Placeholder: Write in your own words how AI helped you during the task -->

## Questions

### 1. Where is the list of alerts kept and how does the Dashboard learn about a resolved alert?
The list of alerts is maintained in memory inside the `AlertsProvider` class (`lib/state/alerts_provider.dart`) as a private field `_data!.alerts`. When an alert is resolved on the Alert Detail screen, the `provider.resolveAlert(alertId)` method is invoked. This replaces the target alert with a resolved copy (`alert.copyWith(status: AlertStatus.resolved)`) and calls `notifyListeners()`. Because the application is wrapped in a top-level `ChangeNotifierProvider` at the root of `main.dart`, both `DashboardScreen` and `AlertsScreen` listen to the exact same provider instance using `context.watch<AlertsProvider>()`. Calling `notifyListeners()` instantly triggers a rebuild of the dashboard widgets, which re-evaluates `openAlertsCount` and `highOpenAlertsCount` in real time with no page reload.

### 2. What would need to be changed to use a real API instead of the local JSON file?
Only the data layer (`lib/data/alert_repository.dart`) would need modification:
1. Replace `rootBundle.loadString('assets/alerts.json')` with an HTTP client call (e.g., using `package:http`) to send a `GET` request to the backend endpoint (e.g. `client.get(Uri.parse('https://api.bugsmirror.com/v1/alerts'))`).
2. Add an API resolution method, such as `Future<void> resolveAlertApi(String alertId)`, that sends a `POST` or `PATCH` request to the backend (e.g., `/v1/alerts/{id}/resolve`).
3. Inside `AlertsProvider.resolveAlert(alertId)`, call `await _repository.resolveAlertApi(alertId)` to persist the change on the server before or alongside updating the local in-memory list and notifying listeners.
The UI screens, router, widgets, and models would remain untouched because they interact exclusively with the repository abstraction and provider contract.

## Video
https://drive.google.com/file/d/1BXswUcD4aP_p5JbqJ0KSvhkjN_w9lUaG/view?usp=drive_link

<!-- Placeholder: Paste your screen recording / demo video link here -->
