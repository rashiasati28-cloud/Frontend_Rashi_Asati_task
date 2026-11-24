import 'alert_item.dart';
import 'app_info.dart';

// Container holding the parsed lists of apps and alerts
class AlertData {
  final List<AppInfo> apps;
  final List<AlertItem> alerts;

  const AlertData({
    required this.apps,
    required this.alerts,
  });

  // Find app by its unique ID
  AppInfo? findApp(String appId) {
    try {
      return apps.firstWhere((app) => app.id == appId);
    } catch (_) {
      return null;
    }
  }

  // Returns formatted app display name or "Unknown app" if appId doesn't match
  String appDisplayName(String appId) {
    final app = findApp(appId);
    return app?.displayName ?? 'Unknown app';
  }
}
