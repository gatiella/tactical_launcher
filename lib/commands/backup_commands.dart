import 'dart:io';
import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../services/backup_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class BackupCommand extends BaseCommand {
  final BackupService backupService;

  BackupCommand(this.backupService);

  @override
  String get name => 'backup';

  @override
  String get description => 'Create and manage backups';

  @override
  String get usage => 'backup <create|list|restore|delete> [file]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No action specified');
    }

    final action = args[0];

    switch (action) {
      case 'create':
        return await _createBackup(shellService);
      
      case 'list':
        return await _listBackups(shellService);
      
      case 'restore':
        if (args.length < 2) {
          shellService.addOutput('Usage: backup restore <file>', type: LineType.error);
          return CommandResult.error('No file specified');
        }
        return await _restoreBackup(args[1], shellService);
      
      case 'delete':
        if (args.length < 2) {
          shellService.addOutput('Usage: backup delete <file>', type: LineType.error);
          return CommandResult.error('No file specified');
        }
        return await _deleteBackup(args[1], shellService);
      
      case 'info':
        if (args.length < 2) {
          shellService.addOutput('Usage: backup info <file>', type: LineType.error);
          return CommandResult.error('No file specified');
        }
        return await _showBackupInfo(args[1], shellService);
      
      default:
        shellService.addOutput('Unknown action: $action', type: LineType.error);
        printHelp(shellService);
        return CommandResult.error('Unknown action');
    }
  }

  Future<CommandResult> _createBackup(ShellService shellService) async {
    shellService.addOutput('Creating backup...');
    
    try {
      final backupPath = await backupService.createBackup();
      final file = File(backupPath);
      final size = await file.length();
      final sizeMB = (size / 1024 / 1024).toStringAsFixed(2);
      
      shellService.addOutput('✓ Backup created successfully', type: LineType.success);
      shellService.addOutput('  Location: $backupPath');
      shellService.addOutput('  Size: ${sizeMB}MB');
      
      return CommandResult.success('Backup created');
    } catch (e) {
      shellService.addOutput('✗ Backup failed: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _listBackups(ShellService shellService) async {
    final backups = await backupService.listBackups();
    
    if (backups.isEmpty) {
      shellService.addOutput('No backups found', type: LineType.info);
      shellService.addOutput('Create backup: backup create');
      return CommandResult.success('No backups');
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('AVAILABLE BACKUPS', type: LineType.info);
    shellService.addOutput('═' * 50);

    for (var i = 0; i < backups.length; i++) {
      final backup = backups[i];
      final file = File(backup.path);
      final stat = await file.stat();
      final size = (stat.size / 1024).toStringAsFixed(2);
      final name = backup.path.split('/').last;
      
      shellService.addOutput('[$i] $name');
      shellService.addOutput('    Size: ${size}KB | Modified: ${stat.modified}', type: LineType.info);
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('Restore: backup restore <index>');
    
    return CommandResult.success('Listed ${backups.length} backups');
  }

  Future<CommandResult> _restoreBackup(String fileOrIndex, ShellService shellService) async {
    try {
      String filePath;
      
      // Check if it's an index
      final index = int.tryParse(fileOrIndex);
      if (index != null) {
        final backups = await backupService.listBackups();
        if (index < 0 || index >= backups.length) {
          shellService.addOutput('Invalid backup index', type: LineType.error);
          return CommandResult.error('Invalid index');
        }
        filePath = backups[index].path;
      } else {
        filePath = fileOrIndex;
      }

      shellService.addOutput('Restoring backup from: $filePath');
      shellService.addOutput('⚠ This will overwrite current settings', type: LineType.warning);
      
      final success = await backupService.restoreBackup(filePath);
      
      if (success) {
        shellService.addOutput('✓ Backup restored successfully', type: LineType.success);
        shellService.addOutput('  Restart launcher to apply changes');
        return CommandResult.success('Backup restored');
      } else {
        shellService.addOutput('✗ Restore failed', type: LineType.error);
        return CommandResult.error('Restore failed');
      }
    } catch (e) {
      shellService.addOutput('✗ Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _deleteBackup(String fileOrIndex, ShellService shellService) async {
    try {
      String filePath;
      
      final index = int.tryParse(fileOrIndex);
      if (index != null) {
        final backups = await backupService.listBackups();
        if (index < 0 || index >= backups.length) {
          shellService.addOutput('Invalid backup index', type: LineType.error);
          return CommandResult.error('Invalid index');
        }
        filePath = backups[index].path;
      } else {
        filePath = fileOrIndex;
      }

      final success = await backupService.deleteBackup(filePath);
      
      if (success) {
        shellService.addOutput('✓ Backup deleted', type: LineType.success);
        return CommandResult.success('Backup deleted');
      } else {
        shellService.addOutput('✗ Delete failed', type: LineType.error);
        return CommandResult.error('Delete failed');
      }
    } catch (e) {
      shellService.addOutput('✗ Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _showBackupInfo(String fileOrIndex, ShellService shellService) async {
    try {
      String filePath;
      
      final index = int.tryParse(fileOrIndex);
      if (index != null) {
        final backups = await backupService.listBackups();
        if (index < 0 || index >= backups.length) {
          shellService.addOutput('Invalid backup index', type: LineType.error);
          return CommandResult.error('Invalid index');
        }
        filePath = backups[index].path;
      } else {
        filePath = fileOrIndex;
      }

      final info = await backupService.getBackupInfo(filePath);
      
      if (info == null) {
        shellService.addOutput('Unable to read backup info', type: LineType.error);
        return CommandResult.error('Read failed');
      }

      shellService.addOutput('═' * 50);
      shellService.addOutput('BACKUP INFORMATION', type: LineType.info);
      shellService.addOutput('═' * 50);
      shellService.addOutput('Version:  ${info['version']}');
      shellService.addOutput('Date:     ${info['date']}');
      shellService.addOutput('Type:     ${info['type']}');
      shellService.addOutput('Size:     ${(info['size'] / 1024).toStringAsFixed(2)}KB');
      shellService.addOutput('═' * 50);
      
      return CommandResult.success('Info displayed');
    } catch (e) {
      shellService.addOutput('✗ Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}