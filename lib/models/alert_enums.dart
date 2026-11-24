// Severity levels for alerts, ordered High -> Medium -> Low
enum Severity {
  high('High', 1),
  medium('Medium', 2),
  low('Low', 3);

  final String label;
  final int priority; // 1 = highest priority, 3 = lowest priority

  const Severity(this.label, this.priority);

  // Safe parsing: handles any letter casing, defaults to Low
  static Severity fromString(dynamic value) {
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'high') return Severity.high;
      if (normalized == 'medium') return Severity.medium;
      if (normalized == 'low') return Severity.low;
    }
    return Severity.low;
  }
}

// Status of an alert: Open or Resolved
enum AlertStatus {
  open('Open'),
  resolved('Resolved');

  final String label;

  const AlertStatus(this.label);

  // Safe parsing: unknown status defaults to Open
  static AlertStatus fromString(dynamic value) {
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'resolved') return AlertStatus.resolved;
    }
    return AlertStatus.open;
  }
}
