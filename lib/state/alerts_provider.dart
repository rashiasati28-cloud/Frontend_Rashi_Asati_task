import 'package:flutter/foundation.dart';
import '../data/alert_repository.dart';
import '../models/alert_data.dart';
import '../models/alert_enums.dart';
import '../models/alert_item.dart';

// State manager for security alerts, handling data loading, filters, sorting, and resolving
class AlertsProvider extends ChangeNotifier {
  final AlertRepository _repository;

  AlertsProvider(this._repository);

  // Core state
  AlertData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state (null means "All")
  String? _selectedAppId;
  Severity? _selectedSeverity;
  AlertStatus? _selectedStatus;

  // Sort state: 'newest' or 'severity'
  String _sortBy = 'newest';

  // Pagination state
  int _currentPage = 1;
  static const int itemsPerPage = 5;

  // Getters for UI
  AlertData? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedAppId => _selectedAppId;
  Severity? get selectedSeverity => _selectedSeverity;
  AlertStatus? get selectedStatus => _selectedStatus;
  String get sortBy => _sortBy;
  int get currentPage {
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    return _currentPage;
  }

  // Dashboard metrics
  int get totalAlertsCount => _data?.alerts.length ?? 0;

  int get openAlertsCount =>
      _data?.alerts.where((alert) => alert.status == AlertStatus.open).length ?? 0;

  int get highOpenAlertsCount =>
      _data?.alerts
          .where((alert) => alert.status == AlertStatus.open && alert.severity == Severity.high)
          .length ??
      0;

  // Count open alerts for a specific app
  int openAlertsCountForApp(String appId) {
    if (_data == null) return 0;
    return _data!.alerts
        .where((alert) => alert.appId == appId && alert.status == AlertStatus.open)
        .length;
  }

  // Find an alert by its ID (for Alert Detail screen)
  AlertItem? getAlertById(String id) {
    if (_data == null) return null;
    try {
      return _data!.alerts.firstWhere((alert) => alert.id == id);
    } catch (_) {
      return null;
    }
  }

  // List of alerts after applying filters and sorting
  List<AlertItem> get filteredAlerts {
    if (_data == null) return [];

    // 1. Filter by App, Severity, and Status
    final filtered = _data!.alerts.where((alert) {
      if (_selectedAppId != null && alert.appId != _selectedAppId) {
        return false;
      }
      if (_selectedSeverity != null && alert.severity != _selectedSeverity) {
        return false;
      }
      if (_selectedStatus != null && alert.status != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();

    // 2. Sort the filtered list
    filtered.sort((a, b) {
      if (_sortBy == 'severity') {
        // High (1) -> Medium (2) -> Low (3)
        final severityComp = a.severity.priority.compareTo(b.severity.priority);
        if (severityComp != 0) return severityComp;

        // Inside same severity: newest first (null reportedAt sorts last)
        if (a.reportedAt == null && b.reportedAt == null) return 0;
        if (a.reportedAt == null) return 1;
        if (b.reportedAt == null) return -1;
        return b.reportedAt!.compareTo(a.reportedAt!);
      } else {
        // Default: Newest first (null reportedAt sorts last)
        if (a.reportedAt == null && b.reportedAt == null) return 0;
        if (a.reportedAt == null) return 1;
        if (b.reportedAt == null) return -1;
        return b.reportedAt!.compareTo(a.reportedAt!);
      }
    });

    return filtered;
  }

  // Total pages calculation (at least 1 page even if empty)
  int get totalPages {
    final count = filteredAlerts.length;
    final pages = (count / itemsPerPage).ceil();
    return pages > 0 ? pages : 1;
  }

  // The 5 alerts to display on the current page
  List<AlertItem> get paginatedAlerts {
    final all = filteredAlerts;
    if (all.isEmpty) return [];

    // Ensure current page does not exceed total pages after list count decreases
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }

    final startIndex = (_currentPage - 1) * itemsPerPage;
    if (startIndex >= all.length) return [];

    final endIndex = (startIndex + itemsPerPage).clamp(0, all.length);
    return all.sublist(startIndex, endIndex);
  }

  // Load data from repository
  Future<void> loadAlerts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _repository.fetchAlertData();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Retry loading
  void retry() {
    loadAlerts();
  }

  // Filter setters (all reset page to 1)
  void setAppFilter(String? appId) {
    _selectedAppId = appId;
    _currentPage = 1;
    notifyListeners();
  }

  void setSeverityFilter(Severity? severity) {
    _selectedSeverity = severity;
    _currentPage = 1;
    notifyListeners();
  }

  void setStatusFilter(AlertStatus? status) {
    _selectedStatus = status;
    _currentPage = 1;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _currentPage = 1;
    notifyListeners();
  }

  // Reset all filters and sort to default, optionally selecting a specific app
  void resetFiltersAndPagination([String? appId]) {
    _selectedAppId = appId;
    _selectedSeverity = null;
    _selectedStatus = null;
    _sortBy = 'newest';
    _currentPage = 1;
    notifyListeners();
  }

  // Pagination actions
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }

  // Mark an open alert as resolved in memory (no disk/JSON write)
  void resolveAlert(String alertId) {
    if (_data == null) return;

    final index = _data!.alerts.indexWhere((alert) => alert.id == alertId);
    if (index != -1) {
      // Create a copy with status resolved
      final updatedAlert = _data!.alerts[index].copyWith(status: AlertStatus.resolved);
      _data!.alerts[index] = updatedAlert;

      // Ensure current page does not exceed total pages after list count decreases
      if (_currentPage > totalPages) {
        _currentPage = totalPages;
      }

      // Notify all screens to immediately update counts and views
      notifyListeners();
    }
  }
}
