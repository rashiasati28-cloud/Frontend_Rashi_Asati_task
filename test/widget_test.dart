import 'package:flutter_test/flutter_test.dart';
import 'package:security_alerts_dashboard/constants/threat_names.dart';
import 'package:security_alerts_dashboard/data/alert_repository.dart';
import 'package:security_alerts_dashboard/models/alert_enums.dart';
import 'package:security_alerts_dashboard/models/alert_item.dart';
import 'package:security_alerts_dashboard/models/app_info.dart';
import 'package:security_alerts_dashboard/state/alerts_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Constants & Enums verification', () {
    test('Threat name mapping returns human readable names and raw fallbacks', () {
      expect(threatName('ROOT_DETECTED'), 'Rooted device');
      expect(threatName('JAILBREAK_DETECTED'), 'Jailbroken iPhone');
      expect(threatName('HOOKING_FRAMEWORK'), 'Hooking tool (like Frida)');
      expect(threatName('SCREEN_OVERLAY'), 'Screen overlay');
      expect(threatName('APP_TAMPERED'), 'App was modified');
      expect(threatName('EMULATOR'), 'Running on an emulator');
      expect(threatName('DEBUGGER_ATTACHED'), 'Debugger attached');
      // Unmapped raw threat code
      expect(threatName('SCREEN_RECORDING'), 'SCREEN_RECORDING');
      expect(threatName(''), 'Unknown threat');
      expect(threatName(null), 'Unknown threat');
    });

    test('Severity enum parses case-insensitively and falls back to Low', () {
      expect(Severity.fromString('HIGH'), Severity.high);
      expect(Severity.fromString('high'), Severity.high);
      expect(Severity.fromString('MEDIUM'), Severity.medium);
      expect(Severity.fromString('medium'), Severity.medium);
      expect(Severity.fromString('LOW'), Severity.low);
      expect(Severity.fromString('Low'), Severity.low);
      expect(Severity.fromString('invalid'), Severity.low);
      expect(Severity.fromString(null), Severity.low);
    });

    test('AlertStatus enum parses safely', () {
      expect(AlertStatus.fromString('open'), AlertStatus.open);
      expect(AlertStatus.fromString('resolved'), AlertStatus.resolved);
      expect(AlertStatus.fromString('RESOLVED'), AlertStatus.resolved);
      expect(AlertStatus.fromString('unknown'), AlertStatus.open);
    });

    test('AppInfo platform display is normalized', () {
      const androidApp = AppInfo(id: 'app_1', name: 'QuickPay', platform: 'android');
      expect(androidApp.displayName, 'QuickPay (Android)');

      const iosApp = AppInfo(id: 'app_2', name: 'QuickPay', platform: 'ios');
      expect(iosApp.displayName, 'QuickPay (iOS)');
    });

    test('Date formatting helper converts UTC ms to local readable string', () {
      expect(formatReportedAt(null), '-');
      final formatted = formatReportedAt(1795317000000);
      expect(formatted, isNotEmpty);
      expect(formatted, isNot('-'));
    });
  });

  group('Data loading, expected metrics & resolution verification', () {
    test('AlertRepository loads 14 alerts and matches expected metrics', () async {
      final repository = AlertRepository();
      final data = await repository.fetchAlertData();

      expect(data.apps.length, 3);
      expect(data.alerts.length, 14);

      final provider = AlertsProvider(repository);
      await provider.loadAlerts();

      // Rule: Total alerts 14, Open alerts 11, High severity open alerts 5
      expect(provider.totalAlertsCount, 14);
      expect(provider.openAlertsCount, 11);
      expect(provider.highOpenAlertsCount, 5);

      // Rule: Open alerts per app: QuickPay (Android) 6, QuickPay (iOS) 3, ShopKart (Android) 2
      expect(provider.openAlertsCountForApp('app_1'), 6);
      expect(provider.openAlertsCountForApp('app_2'), 3);
      expect(provider.openAlertsCountForApp('app_3'), 2);

      // Rule: Alerts screen with no filters: "Page 1 of 3" (5 + 5 + 4 alerts)
      expect(provider.totalPages, 3);
      expect(provider.paginatedAlerts.length, 5);
      provider.nextPage();
      expect(provider.currentPage, 2);
      expect(provider.paginatedAlerts.length, 5);
      provider.nextPage();
      expect(provider.currentPage, 3);
      expect(provider.paginatedAlerts.length, 4);

      // Rule: Filter Severity = High: 7 alerts -> "Page 1 of 2"
      provider.setSeverityFilter(Severity.high);
      expect(provider.filteredAlerts.length, 7);
      expect(provider.totalPages, 2);
      expect(provider.currentPage, 1);
      expect(provider.paginatedAlerts.length, 5);
      provider.nextPage();
      expect(provider.currentPage, 2);
      expect(provider.paginatedAlerts.length, 2);

      // Rule: Resolving one open High alert lowers Open alerts to 10 and High open to 4, immediately
      provider.resetFiltersAndPagination();
      final highOpenAlert = provider.data!.alerts.firstWhere(
        (a) => a.severity == Severity.high && a.status == AlertStatus.open,
      );
      provider.resolveAlert(highOpenAlert.id);

      expect(provider.totalAlertsCount, 14);
      expect(provider.openAlertsCount, 10);
      expect(provider.highOpenAlertsCount, 4);

      // Edge case: resolving on the last page clamps page number to totalPages
      provider.setAppFilter('app_1'); // 7 total alerts for app_1 -> 2 pages
      expect(provider.totalPages, 2);
      provider.nextPage();
      expect(provider.currentPage, 2);
      // Resolving alerts so that only 5 remain
      final app1Alerts = provider.filteredAlerts.where((a) => a.status == AlertStatus.open).toList();
      provider.resolveAlert(app1Alerts[0].id);
      provider.resolveAlert(app1Alerts[1].id);
      // Now totalPages drops, and currentPage must be clamped
      expect(provider.currentPage, provider.totalPages);
      expect(provider.paginatedAlerts, isNotEmpty);
    });

    test('Messy data handling: null deviceModel -> Unknown, missing osVersion -> -', () async {
      final repository = AlertRepository();
      final data = await repository.fetchAlertData();

      final al103 = data.alerts.firstWhere((a) => a.id == 'al_103');
      expect(al103.deviceModel, 'Unknown');

      final al107 = data.alerts.firstWhere((a) => a.id == 'al_107');
      expect(al107.osVersion, '-');
      expect(al107.threatType, 'SCREEN_RECORDING');
      expect(threatName(al107.threatType), 'SCREEN_RECORDING');
    });
  });
}
