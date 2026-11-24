import 'package:intl/intl.dart';
import 'alert_enums.dart';

// Single helper function to format milliseconds timestamp into readable local date/time
// Converts UTC milliseconds to local time, formatted like "22 Nov 2026, 2:00 AM"
String formatReportedAt(int? ms) {
  if (ms == null) return '-';
  try {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    return DateFormat('d MMM y, h:mm a').format(dateTime);
  } catch (_) {
    return '-';
  }
}

// Represents an individual security alert
class AlertItem {
  final String id;
  final String appId;
  final String threatType;
  final Severity severity;
  final String deviceModel;
  final String osVersion;
  final int? reportedAt; // Milliseconds since 1970 UTC
  final AlertStatus status;

  const AlertItem({
    required this.id,
    required this.appId,
    required this.threatType,
    required this.severity,
    required this.deviceModel,
    required this.osVersion,
    required this.reportedAt,
    required this.status,
  });

  // Safe JSON constructor with fallback defaults for messy/missing data
  factory AlertItem.fromJson(Map<String, dynamic> json) {
    // Missing or null deviceModel becomes "Unknown"
    final rawDevice = json['deviceModel'];
    final safeDevice = (rawDevice == null || rawDevice.toString().trim().isEmpty)
        ? 'Unknown'
        : rawDevice.toString();

    // Missing or null osVersion becomes "-"
    final rawOs = json['osVersion'];
    final safeOs = (rawOs == null || rawOs.toString().trim().isEmpty)
        ? '-'
        : rawOs.toString();

    // Safely parse reportedAt timestamp
    int? safeReportedAt;
    if (json['reportedAt'] is int) {
      safeReportedAt = json['reportedAt'] as int;
    } else if (json['reportedAt'] != null) {
      safeReportedAt = int.tryParse(json['reportedAt'].toString());
    }

    return AlertItem(
      id: json['id']?.toString() ?? '',
      appId: json['appId']?.toString() ?? '',
      threatType: json['threatType']?.toString() ?? '',
      severity: Severity.fromString(json['severity']),
      deviceModel: safeDevice,
      osVersion: safeOs,
      reportedAt: safeReportedAt,
      status: AlertStatus.fromString(json['status']),
    );
  }

  // Returns a copy of the alert with updated fields (used when resolving in memory)
  AlertItem copyWith({
    String? id,
    String? appId,
    String? threatType,
    Severity? severity,
    String? deviceModel,
    String? osVersion,
    int? reportedAt,
    AlertStatus? status,
  }) {
    return AlertItem(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      threatType: threatType ?? this.threatType,
      severity: severity ?? this.severity,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
    );
  }

  // Formatted date string for display
  String get formattedReportedAt => formatReportedAt(reportedAt);
}
