import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/threat_names.dart';
import '../models/alert_enums.dart';
import '../models/alert_item.dart';
import '../state/alerts_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/severity_chip.dart';

// Screen 2: Security Alerts list with filters, sorting, and pagination
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () {
            // If can pop, pop back; otherwise go to dashboard
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Builder(
        builder: (context) {
          // 1. Loading state
          if (provider.isLoading) {
            return const LoadingView(message: 'Loading alerts...');
          }

          // 2. Error state
          if (provider.errorMessage != null) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.retry(),
            );
          }

          final data = provider.data;
          if (data == null) {
            return const LoadingView();
          }

          final paginatedList = provider.paginatedAlerts;
          final totalMatches = provider.filteredAlerts.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filters & sorting control panel
                    _buildFilterAndSortSection(context, provider),

                    const SizedBox(height: 16),

                    // Results header count
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Showing $totalMatches ${totalMatches == 1 ? 'alert' : 'alerts'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (provider.selectedAppId != null ||
                            provider.selectedSeverity != null ||
                            provider.selectedStatus != null ||
                            provider.sortBy != 'newest')
                          TextButton.icon(
                            onPressed: () => provider.resetFiltersAndPagination(),
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Reset filters'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Empty state or alerts list
                    if (paginatedList.isEmpty)
                      _buildEmptyState(provider)
                    else ...[
                      // List of alerts (5 per page)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: paginatedList.length,
                        itemBuilder: (context, index) {
                          final alert = paginatedList[index];
                          return _buildAlertCard(context, provider, alert);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Pagination bar
                      _buildPaginationBar(provider),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Filter and Sort dropdowns (wrapped responsively for narrow screens)
  Widget _buildFilterAndSortSection(BuildContext context, AlertsProvider provider) {
    final apps = provider.data?.apps ?? [];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // App Filter
            _buildDropdownContainer(
              label: 'App',
              child: DropdownButton<String?>(
                value: provider.selectedAppId,
                isDense: true,
                underline: const SizedBox(),
                hint: const Text('All Apps'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Apps'),
                  ),
                  ...apps.map((app) {
                    return DropdownMenuItem<String?>(
                      value: app.id,
                      child: Text(app.displayName),
                    );
                  }),
                ],
                onChanged: (newAppId) {
                  provider.setAppFilter(newAppId);
                },
              ),
            ),

            // Severity Filter (Order: High -> Medium -> Low, never alphabetical)
            _buildDropdownContainer(
              label: 'Severity',
              child: DropdownButton<Severity?>(
                value: provider.selectedSeverity,
                isDense: true,
                underline: const SizedBox(),
                hint: const Text('All Severities'),
                items: const [
                  DropdownMenuItem<Severity?>(
                    value: null,
                    child: Text('All Severities'),
                  ),
                  DropdownMenuItem<Severity?>(
                    value: Severity.high,
                    child: Text('High'),
                  ),
                  DropdownMenuItem<Severity?>(
                    value: Severity.medium,
                    child: Text('Medium'),
                  ),
                  DropdownMenuItem<Severity?>(
                    value: Severity.low,
                    child: Text('Low'),
                  ),
                ],
                onChanged: (newSeverity) {
                  provider.setSeverityFilter(newSeverity);
                },
              ),
            ),

            // Status Filter (All, Open, Resolved)
            _buildDropdownContainer(
              label: 'Status',
              child: DropdownButton<AlertStatus?>(
                value: provider.selectedStatus,
                isDense: true,
                underline: const SizedBox(),
                hint: const Text('All Statuses'),
                items: const [
                  DropdownMenuItem<AlertStatus?>(
                    value: null,
                    child: Text('All Statuses'),
                  ),
                  DropdownMenuItem<AlertStatus?>(
                    value: AlertStatus.open,
                    child: Text('Open'),
                  ),
                  DropdownMenuItem<AlertStatus?>(
                    value: AlertStatus.resolved,
                    child: Text('Resolved'),
                  ),
                ],
                onChanged: (newStatus) {
                  provider.setStatusFilter(newStatus);
                },
              ),
            ),

            // Sort Dropdown
            _buildDropdownContainer(
              label: 'Sort',
              child: DropdownButton<String>(
                value: provider.sortBy,
                isDense: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'newest',
                    child: Text('Newest first'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'severity',
                    child: Text('Severity (High to Low)'),
                  ),
                ],
                onChanged: (newSort) {
                  if (newSort != null) {
                    provider.setSortBy(newSort);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper box around each dropdown
  Widget _buildDropdownContainer({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          child,
        ],
      ),
    );
  }

  // Alert card row item
  Widget _buildAlertCard(BuildContext context, AlertsProvider provider, AlertItem alert) {
    final appLabel = provider.data?.appDisplayName(alert.appId) ?? 'Unknown app';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // Tapping an alert opens /alerts/:id
          context.push('/alerts/${alert.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: mapped threat name + SeverityChip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      threatName(alert.threatType),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SeverityChip(severity: alert.severity),
                ],
              ),

              const SizedBox(height: 10),

              // Metadata row: App, Device model, Reported time, Status
              Wrap(
                spacing: 16,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildMetaItem(Icons.apps, appLabel),
                  _buildMetaItem(Icons.phone_android, alert.deviceModel),
                  _buildMetaItem(Icons.access_time, alert.formattedReportedAt),
                  _buildStatusChip(alert.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Metadata snippet with an icon
  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  // Status badge for the card: Open or Resolved
  Widget _buildStatusChip(AlertStatus status) {
    final isOpen = status == AlertStatus.open;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOpen ? const Color(0xFFFFD54F) : const Color(0xFFA5D6A7),
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOpen ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
        ),
      ),
    );
  }

  // Empty state when no alerts match filters
  Widget _buildEmptyState(AlertsProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No alerts match these filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting or resetting your filter criteria.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => provider.resetFiltersAndPagination(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset all filters'),
          ),
        ],
      ),
    );
  }

  // Pagination navigation bar
  Widget _buildPaginationBar(AlertsProvider provider) {
    final currentPage = provider.currentPage;
    final totalPages = provider.totalPages;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous button (disabled on page 1)
            OutlinedButton.icon(
              onPressed: currentPage > 1 ? () => provider.previousPage() : null,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Previous'),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Text(
                'Page $currentPage of $totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Next button (disabled on last page)
            OutlinedButton.icon(
              onPressed: currentPage < totalPages ? () => provider.nextPage() : null,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
