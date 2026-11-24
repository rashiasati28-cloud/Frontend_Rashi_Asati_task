// Represents an application registered in the dashboard
class AppInfo {
  final String id;
  final String name;
  final String platform; // Lowercase raw string from data, e.g. "android", "ios"

  const AppInfo({
    required this.id,
    required this.name,
    required this.platform,
  });

  // Safe JSON deserializer
  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      platform: json['platform']?.toString().toLowerCase().trim() ?? '',
    );
  }

  // Display platform with standard capitalization: Android / iOS
  String get formattedPlatform {
    if (platform == 'ios') return 'iOS';
    if (platform == 'android') return 'Android';
    if (platform.isNotEmpty) {
      return platform[0].toUpperCase() + platform.substring(1);
    }
    return '';
  }

  // Full display name format, e.g. "QuickPay (iOS)"
  String get displayName {
    if (formattedPlatform.isEmpty) {
      return name;
    }
    return '$name ($formattedPlatform)';
  }
}
