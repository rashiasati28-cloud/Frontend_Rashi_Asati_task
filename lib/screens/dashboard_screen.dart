import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/app_info.dart';
import '../state/alerts_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/summary_card.dart';

// Screen 1: Security Alerts Dashboard overview
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security Alerts Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: Builder(
        builder: (context) {
          // 1. Loading state
          if (provider.isLoading) {
            return const LoadingView(message: 'Loading security dashboard...');
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

          // 3. Responsive content container
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary metrics section
                    _buildSummaryCards(context, provider),

                    const SizedBox(height: 28),

                    // Monitored apps section header + "View all alerts" button
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'Monitored Applications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            // Reset filters to defaults and open alerts
                            provider.resetFiltersAndPagination(null);
                            context.push('/alerts');
                          },
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: const Text('View all alerts'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // List of apps with open alert counts
                    _buildAppsList(context, provider, data.apps),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Responsive 3 summary cards: Total, Open, High severity open
  Widget _buildSummaryCards(BuildContext context, AlertsProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If screen width is narrow (< 600px), display in a column
        final isNarrow = constraints.maxWidth < 600;

        final totalCard = SummaryCard(
          title: 'Total Alerts',
          value: provider.totalAlertsCount.toString(),
          icon: Icons.notifications_none,
          accentColor: const Color(0xFF1976D2), // Blue
        );

        final openCard = SummaryCard(
          title: 'Open Alerts',
          value: provider.openAlertsCount.toString(),
          icon: Icons.warning_amber_rounded,
          accentColor: const Color(0xFFF57C00), // Orange
        );

        final highOpenCard = SummaryCard(
          title: 'High Severity Open',
          value: provider.highOpenAlertsCount.toString(),
          icon: Icons.shield_outlined,
          accentColor: const Color(0xFFD32F2F), // Red
        );

        if (isNarrow) {
          return Column(
            children: [
              totalCard,
              const SizedBox(height: 10),
              openCard,
              const SizedBox(height: 10),
              highOpenCard,
            ],
          );
        }

        // Horizontal row for wide screens
        return Row(
          children: [
            Expanded(child: totalCard),
            const SizedBox(width: 12),
            Expanded(child: openCard),
            const SizedBox(width: 12),
            Expanded(child: highOpenCard),
          ],
        );
      },
    );
  }

  // List of monitored apps
  Widget _buildAppsList(BuildContext context, AlertsProvider provider, List<AppInfo> apps) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apps.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final app = apps[index];
        final openCount = provider.openAlertsCountForApp(app.id);

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              // Tapping an app: reset all filters/sort/page to defaults, set App filter to this app, then push /alerts
              provider.resetFiltersAndPagination(app.id);
              context.push('/alerts');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  // Platform icon
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(
                      app.platform == 'ios' ? Icons.apple : Icons.android,
                      color: app.platform == 'ios' ? Colors.black87 : Colors.green.shade700,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // App label with platform
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Platform: ${app.formattedPlatform}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Open alerts count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: openCount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: openCount > 0 ? Colors.orange.shade200 : Colors.green.shade200,
                      ),
                    ),
                    child: Text(
                      '$openCount open ${openCount == 1 ? 'alert' : 'alerts'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: openCount > 0 ? Colors.orange.shade900 : Colors.green.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
