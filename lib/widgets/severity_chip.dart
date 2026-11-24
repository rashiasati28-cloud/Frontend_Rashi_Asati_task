import 'package:flutter/material.dart';
import '../models/alert_enums.dart';

// Reusable chip widget to display alert severity
// Uses distinct colors: High = red, Medium = orange, Low = grey
class SeverityChip extends StatelessWidget {
  final Severity severity;

  const SeverityChip({
    super.key,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    // Determine chip colors based on severity
    final Color textColor;
    final Color backgroundColor;
    final Color borderColor;

    switch (severity) {
      case Severity.high:
        textColor = const Color(0xFFC62828); // Deep red
        backgroundColor = const Color(0xFFFFEBEE); // Soft red background
        borderColor = const Color(0xFFEF9A9A);
        break;
      case Severity.medium:
        textColor = const Color(0xFFEF6C00); // Deep orange
        backgroundColor = const Color(0xFFFFF3E0); // Soft orange background
        borderColor = const Color(0xFFFFCC80);
        break;
      case Severity.low:
        textColor = const Color(0xFF424242); // Dark grey
        backgroundColor = const Color(0xFFEEEEEE); // Soft grey background
        borderColor = const Color(0xFFBDBDBD);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            severity.label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
