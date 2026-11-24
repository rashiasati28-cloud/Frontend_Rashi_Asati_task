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

// Screen 3: Detailed view of a single alert with confirmation dialog to resolve
class AlertDetailScreen extends StatelessWidget {
  final String alertId;

  const AlertDetailScreen({
    super.key,
    required this.alertId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alert Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/alerts');
            }
          },
        ),
      ),
      body: Builder(
        builder: (context) {
          // 1. Loading state
          if (provider.isLoading) {
            return const LoadingView(message: 'Loading alert details...');
          }

          // 2. Error state
          if (provider.errorMessage != null) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.retry(),
            );
          }

          // 3. Waiting for data state (e.g. direct page refresh)
          if (provider.data == null) {
            return const LoadingView(message: 'Loading alert details...');
          }

          // 4. Find alert by ID
          final alert = provider.getAlertById(alertId);

          // If ID does not exist, display friendly "Alert not found" message
          if (alert == null) {
            return _buildNotFoundView(context);
          }

          // 4. Alert detail view
          return _buildDetailContent(context, provider, alert);
        },
      ),
    );
  }

  // Friendly view when an alert is not found
  Widget _buildNotFoundView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Alert not found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No alert was found matching ID "$alertId".',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/alerts'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to alerts list'),
            ),
          ],
        ),
      ),
    );
  }

  // Main content displaying every field of the alert
  Widget _buildDetailContent(BuildContext context, AlertsProvider provider, AlertItem alert) {
    final appLabel = provider.data?.appDisplayName(alert.appId) ?? 'Unknown app';
    final isOpen = alert.status == AlertStatus.open;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Threat title & Severity chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  threatName(alert.threatType),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Alert ID: ${alert.id}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SeverityChip(severity: alert.severity),
                        ],
                      ),

                      const Divider(height: 32),

                      // Every field of the alert listed cleanly:
                      _buildDetailRow('Alert ID', Text(alert.id, style: const TextStyle(fontWeight: FontWeight.w500))),
                      _buildDetailRow('Threat Name', Text(threatName(alert.threatType))),
                      _buildDetailRow(
                        'Raw Threat Code',
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alert.threatType,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      _buildDetailRow('Severity', SeverityChip(severity: alert.severity)),
                      _buildDetailRow('Monitored App', Text(appLabel)),
                      _buildDetailRow('Device Model', Text(alert.deviceModel)),
                      _buildDetailRow('OS Version', Text(alert.osVersion)),
                      _buildDetailRow('Reported Time', Text(alert.formattedReportedAt)),
                      _buildDetailRow(
                        'Status',
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOpen ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isOpen ? const Color(0xFFFFD54F) : const Color(0xFFA5D6A7),
                                ),
                              ),
                              child: Text(
                                alert.status.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isOpen ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons section
              if (isOpen)
                FilledButton.icon(
                  onPressed: () => _showResolveConfirmationDialog(context, provider, alert),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Mark as resolved',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32), // Green
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'This security alert has been marked as resolved.',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Row layout helper for detail fields (responsive with wrapping)
  Widget _buildDetailRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  // "Are you sure?" confirmation dialog before marking an alert as resolved
  void _showResolveConfirmationDialog(
    BuildContext context,
    AlertsProvider provider,
    AlertItem alert,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Resolve Alert?'),
          content: Text(
            'Are you sure you want to mark alert "${alert.id}" (${threatName(alert.threatType)}) as resolved?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // Update in-memory state in the provider
                provider.resolveAlert(alert.id);
                Navigator.of(dialogContext).pop();

                // Show confirmation snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Alert "${alert.id}" marked as resolved.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );
  }
}
