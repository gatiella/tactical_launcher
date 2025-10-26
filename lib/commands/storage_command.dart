import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class StorageCommand extends BaseCommand {
  @override
  String get name => 'storage';

  @override
  String get description => 'Show accessible storage locations';

  @override
  String get usage => 'storage';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    try {
      shellService.addOutput('═' * 50);
      shellService.addOutput(
        'ACCESSIBLE STORAGE LOCATIONS',
        type: LineType.info,
      );
      shellService.addOutput('═' * 50);

      // App documents directory
      final appDir = await getApplicationDocumentsDirectory();
      shellService.addOutput('📁 App Directory:', type: LineType.success);
      shellService.addOutput('   ${appDir.path}');
      shellService.addOutput('   (Recommended for files)');
      shellService.addOutput('');

      // Try external storage
      try {
        final externalDir = Directory('/storage/emulated/0');
        if (await externalDir.exists()) {
          shellService.addOutput(
            '📁 External Storage:',
            type: LineType.success,
          );
          shellService.addOutput('   /storage/emulated/0');
          shellService.addOutput('   (May require permissions)');
          shellService.addOutput('');

          // Common accessible folders
          final commonDirs = [
            '/storage/emulated/0/Download',
            '/storage/emulated/0/Documents',
            '/storage/emulated/0/Pictures',
          ];

          shellService.addOutput('📁 Common Folders:', type: LineType.info);
          for (var dir in commonDirs) {
            final d = Directory(dir);
            if (await d.exists()) {
              shellService.addOutput('   ✓ $dir', type: LineType.success);
            } else {
              shellService.addOutput(
                '   ✗ $dir (not accessible)',
                type: LineType.warning,
              );
            }
          }
        }
      } catch (e) {
        shellService.addOutput(
          'External storage not accessible',
          type: LineType.warning,
        );
      }

      shellService.addOutput('');
      shellService.addOutput('═' * 50);
      shellService.addOutput('Usage:', type: LineType.info);
      shellService.addOutput('  ls ${appDir.path}');
      shellService.addOutput('  cd ${appDir.path}');
      shellService.addOutput('  nano ${appDir.path}/myfile.txt');

      return CommandResult.success('Storage info displayed');
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}
