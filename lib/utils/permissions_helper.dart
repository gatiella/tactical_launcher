import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  static Future<bool> requestStoragePermissions() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestManageExternalStorage() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  static Future<bool> checkAllPermissions() async {
    final storage = await Permission.storage.isGranted;
    final manage = await Permission.manageExternalStorage.isGranted;
    return storage || manage;
  }

  static Future<void> requestAllPermissions() async {
    await requestStoragePermissions();
    await requestManageExternalStorage();
  }
}