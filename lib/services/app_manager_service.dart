import 'package:flutter/foundation.dart';
import 'package:installed_apps/installed_apps.dart';
import '../models/app_info.dart';

class AppManagerService extends ChangeNotifier {
  List<AppInfo> _installedApps = [];
  bool _isLoading = false;

  List<AppInfo> get installedApps => List.unmodifiable(_installedApps);
  bool get isLoading => _isLoading;

  Future<void> loadInstalledApps() async {
    _isLoading = true;
    notifyListeners();

    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false, // Set to true if you want to exclude system apps
        excludeNonLaunchableApps: true, // Only apps with launch intent
        withIcon: false, // Set to true if you need icons
      );

      _installedApps = apps.map((app) {
        return AppInfo(
          name: app.name,
          packageName: app.packageName,
          isSystemApp: app.isSystemApp,
        );
      }).toList();

      _installedApps.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      debugPrint('Error loading apps: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> launchApp(String packageName) async {
    try {
      await InstalledApps.startApp(packageName);
      return true;
    } catch (e) {
      debugPrint('Error launching app: $e');
      return false;
    }
  }

  List<AppInfo> searchApps(String query) {
    if (query.isEmpty) return _installedApps;

    return _installedApps.where((app) {
      return app.name.toLowerCase().contains(query.toLowerCase()) ||
          app.packageName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}