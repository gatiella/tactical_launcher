import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class SetupStorageCommand extends BaseCommand {
  @override
  String get name => 'setup-storage';

  @override
  String get description => 'Setup access to device storage';

  @override
  String get usage => 'setup-storage';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    try {
      if (shellService.isStorageSetup) {
        shellService.addOutput('Storage already setup', type: LineType.success);
        shellService.addOutput('Current home: ${shellService.homeDirectory}');
        return CommandResult.success('Already setup');
      }

      shellService.addOutput('Setting up storage access...');

      await shellService.setupStorage();

      shellService.addOutput(
        '✓ Storage access granted',
        type: LineType.success,
      );
      shellService.addOutput('');
      shellService.addOutput('You can now access device storage:');
      shellService.addOutput(
        '  cd ~/storage        - Access /storage/emulated/0',
      );
      shellService.addOutput('  cd Downloads        - Downloads folder');
      shellService.addOutput('  cd DCIM             - Camera photos');
      shellService.addOutput('  cd Documents        - Documents');
      shellService.addOutput('');
      shellService.addOutput('Or use absolute paths:');
      shellService.addOutput('  cd /storage/emulated/0');

      return CommandResult.success('Storage setup complete');
    } catch (e) {
      shellService.addOutput(
        'Failed to setup storage: $e',
        type: LineType.error,
      );
      shellService.addOutput('');
      shellService.addOutput(
        'Please grant storage permissions:',
        type: LineType.warning,
      );
      shellService.addOutput(
        '  Settings → Apps → Tactical Launcher → Permissions → Storage',
      );
      return CommandResult.error(e.toString());
    }
  }
}
