import 'package:tactical_launcher/commands/base_command.dart';
import 'package:tactical_launcher/models/command_result.dart';
import 'package:tactical_launcher/models/terminal_line.dart';
import 'package:tactical_launcher/services/app_manager_service.dart'
    show AppManagerService;
import 'package:tactical_launcher/services/shell_service.dart';

class FixCommand extends BaseCommand {
  @override
  String get name => 'fix';

  @override
  String get description => 'Show common fixes for errors';

  @override
  String get usage => 'fix [permissions|storage|git]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      _showAllFixes(shellService);
      return CommandResult.success('Fixes displayed');
    }

    switch (args[0]) {
      case 'permissions':
        _showPermissionsFix(shellService);
        break;
      case 'storage':
        _showStorageFix(shellService);
        break;
      case 'git':
        _showGitFix(shellService);
        break;
      default:
        _showAllFixes(shellService);
    }

    return CommandResult.success('Fix info displayed');
  }

  void _showAllFixes(ShellService shellService) {
    shellService.addOutput('═' * 50);
    shellService.addOutput('COMMON FIXES', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('fix permissions  - Storage permission issues');
    shellService.addOutput('fix storage      - File access problems');
    shellService.addOutput('fix git          - Git not found errors');
    shellService.addOutput('═' * 50);
  }

  void _showPermissionsFix(ShellService shellService) {
    shellService.addOutput('═' * 50);
    shellService.addOutput('STORAGE PERMISSIONS FIX', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('1. Go to Android Settings');
    shellService.addOutput('2. Apps → Tactical Launcher');
    shellService.addOutput('3. Permissions → Storage');
    shellService.addOutput('4. Allow storage access');
    shellService.addOutput('');
    shellService.addOutput('Or use accessible directory:', type: LineType.info);
    shellService.addOutput('  storage  (to see accessible paths)');
    shellService.addOutput('═' * 50);
  }

  void _showStorageFix(ShellService shellService) {
    shellService.addOutput('═' * 50);
    shellService.addOutput('STORAGE ACCESS FIX', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('Use these commands:', type: LineType.success);
    shellService.addOutput('  storage  (show accessible paths)');
    shellService.addOutput('  pwd      (current directory)');
    shellService.addOutput('  cd <path> (change to accessible dir)');
    shellService.addOutput('');
    shellService.addOutput('Try:', type: LineType.info);
    shellService.addOutput('  ls /storage/emulated/0/Download');
    shellService.addOutput('  cd /storage/emulated/0/Download');
    shellService.addOutput('═' * 50);
  }

  void _showGitFix(ShellService shellService) {
    shellService.addOutput('═' * 50);
    shellService.addOutput('GIT NOT FOUND FIX', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('Git must be installed separately:');
    shellService.addOutput('');
    shellService.addOutput(
      '1. Install Termux from F-Droid',
      type: LineType.success,
    );
    shellService.addOutput('2. In Termux, run: pkg install git');
    shellService.addOutput('3. Restart this launcher');
    shellService.addOutput('4. Try: git version');
    shellService.addOutput('');
    shellService.addOutput('Note:', type: LineType.warning);
    shellService.addOutput('  Git is not built-in to Android');
    shellService.addOutput('  Termux provides Linux tools');
    shellService.addOutput('═' * 50);
  }
}
