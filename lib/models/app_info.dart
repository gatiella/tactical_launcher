class AppInfo {
  final String name;
  final String packageName;
  final String? icon;
  final bool isSystemApp;

  AppInfo({
    required this.name,
    required this.packageName,
    this.icon,
    this.isSystemApp = false,
  });

  @override
  String toString() => '$name ($packageName)';
}