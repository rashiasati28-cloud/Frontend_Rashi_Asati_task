import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'data/alert_repository.dart';
import 'screens/alert_detail_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'state/alerts_provider.dart';

// GoRouter configuration for the three application screens
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Screen 1: Dashboard
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    // Screen 2: Alerts List
    GoRoute(
      path: '/alerts',
      builder: (context, state) => const AlertsScreen(),
    ),
    // Screen 3: Alert Detail
    GoRoute(
      path: '/alerts/:id',
      builder: (context, state) {
        final alertId = state.pathParameters['id'] ?? '';
        return AlertDetailScreen(alertId: alertId);
      },
    ),
  ],
);

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Provider loads once at app start; all screens read this same instance
        ChangeNotifierProvider(
          create: (_) => AlertsProvider(AlertRepository())..loadAlerts(),
        ),
      ],
      child: const SecurityAlertsApp(),
    ),
  );
}

// Root application widget
class SecurityAlertsApp extends StatelessWidget {
  const SecurityAlertsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Security Alerts Dashboard',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
      ),
    );
  }
}
