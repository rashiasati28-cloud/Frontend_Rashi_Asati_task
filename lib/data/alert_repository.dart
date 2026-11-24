import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/alert_data.dart';
import '../models/alert_item.dart';
import '../models/app_info.dart';

const bool simulateError = false;

// Repository class to load and parse alerts data from assets
class AlertRepository {
  Future<AlertData> fetchAlertData() async {
    // Artificial 1 second delay to simulate network latency
    await Future.delayed(const Duration(seconds: 1));

    // If simulateError is true, throw an exception to test error handling
    if (simulateError) {
      throw Exception('Simulated network error: Failed to fetch alerts from repository.');
    }

    // Load JSON file from assets
    final jsonString = await rootBundle.loadString('assets/alerts.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;

    // Safely extract lists
    final List<dynamic> appsList = jsonMap['apps'] as List<dynamic>? ?? [];
    final List<dynamic> alertsList = jsonMap['alerts'] as List<dynamic>? ?? [];

    final apps = appsList
        .whereType<Map<String, dynamic>>()
        .map((item) => AppInfo.fromJson(item))
        .toList();

    final alerts = alertsList
        .whereType<Map<String, dynamic>>()
        .map((item) => AlertItem.fromJson(item))
        .toList();

    return AlertData(apps: apps, alerts: alerts);
  }
}
