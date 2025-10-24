import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class BackupService extends ChangeNotifier {
  Future<String> createBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final backup = <String, dynamic>{};
      for (var key in keys) {
        final value = prefs.get(key);
        backup[key] = value;
      }

      backup['backup_version'] = '2.0.0';
      backup['backup_date'] = DateTime.now().toIso8601String();
      backup['backup_type'] = 'full';

      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${backupDir.path}/backup_$timestamp.json');
      await backupFile.writeAsString(jsonEncode(backup));

      return backupFile.path;
    } catch (e) {
      debugPrint('Backup error: $e');
      rethrow;
    }
  }

  Future<bool> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final contents = await file.readAsString();
      final backup = jsonDecode(contents) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      for (var entry in backup.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is List) {
          await prefs.setStringList(key, value.cast<String>());
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  Future<List<FileSystemEntity>> listBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      
      if (!await backupDir.exists()) {
        return [];
      }

      return await backupDir.list().where((entity) => 
        entity.path.endsWith('.json')
      ).toList();
    } catch (e) {
      debugPrint('List backups error: $e');
      return [];
    }
  }

  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete backup error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final contents = await file.readAsString();
      final backup = jsonDecode(contents) as Map<String, dynamic>;

      return {
        'version': backup['backup_version'] ?? 'Unknown',
        'date': backup['backup_date'] ?? 'Unknown',
        'type': backup['backup_type'] ?? 'Unknown',
        'size': await file.length(),
      };
    } catch (e) {
      debugPrint('Get backup info error: $e');
      return null;
    }
  }
}