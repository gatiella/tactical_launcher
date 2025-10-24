import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class AppsCommand extends BaseCommand {
  @override
  String get name => 'apps';

  @override
  String get description => 'List all installed applications';

  @override
  String get usage => 'apps [--system] [--user]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    final showSystem = args.contains('--system');
    final showUser = args.contains('--user');
    //final showAll = !showSystem && !showUser;

    shellService.addOutput('Scanning installed applications...');
    
    await appService.loadInstalledApps();
    
    var apps = appService.installedApps;
    
    if (showSystem) {
      apps = apps.where((app) => app.isSystemApp).toList();
    } else if (showUser) {
      apps = apps.where((app) => !app.isSystemApp).toList();
    }

    shellService.addOutput('Found ${apps.length} applications', type: LineType.success);
    shellService.addOutput('═' * 50);

    for (var i = 0; i < apps.length; i++) {
      final app = apps[i];
      shellService.addOutput('[$i] ${app.name}');
      shellService.addOutput('    ${app.packageName}', type: LineType.info);
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('Use "open [number]" or "open [name]" to launch', type: LineType.info);

    return CommandResult.success('Listed ${apps.length} apps');
  }
}

class SearchCommand extends BaseCommand {
  @override
  String get name => 'search';

  @override
  String get description => 'Search for installed applications';

  @override
  String get usage => 'search <query>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No search query provided');
    }

    final query = args.join(' ');
    shellService.addOutput('Searching for "$query"...');

    final results = appService.searchApps(query);

    if (results.isEmpty) {
      shellService.addOutput('No applications found matching "$query"', type: LineType.warning);
      return CommandResult.success('No results');
    }

    shellService.addOutput('Found ${results.length} matches', type: LineType.success);
    shellService.addOutput('═' * 50);

    for (var i = 0; i < results.length; i++) {
      final app = results[i];
      shellService.addOutput('[$i] ${app.name}');
      shellService.addOutput('    ${app.packageName}', type: LineType.info);
    }

    shellService.addOutput('═' * 50);
    
    return CommandResult.success('Found ${results.length} apps');
  }
}

class OpenCommand extends BaseCommand {
  @override
  String get name => 'open';

  @override
  String get description => 'Launch an application';

  @override
  String get usage => 'open <app_name|app_number|package_name>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No app specified');
    }

    final identifier = args.join(' ');
    
    // Check if it's a number (index)
    final index = int.tryParse(identifier);
    String? packageName;

    if (index != null) {
      // Open by index
      if (index >= 0 && index < appService.installedApps.length) {
        packageName = appService.installedApps[index].packageName;
      } else {
        shellService.addOutput('Invalid app number: $index', type: LineType.error);
        return CommandResult.error('Invalid index');
      }
    } else {
      // Search by name or package
      final results = appService.searchApps(identifier);
      
      if (results.isEmpty) {
        shellService.addOutput('App not found: $identifier', type: LineType.error);
        return CommandResult.error('App not found');
      }
      
      if (results.length > 1) {
        shellService.addOutput('Multiple matches found. Please be more specific:', type: LineType.warning);
        for (var i = 0; i < results.length; i++) {
          shellService.addOutput('[$i] ${results[i].name}');
        }
        return CommandResult.error('Multiple matches');
      }
      
      packageName = results.first.packageName;
    }

    shellService.addOutput('▸ Launching application...');
    
    final success = await appService.launchApp(packageName);
    
    if (success) {
      shellService.addOutput('✓ Application launched successfully', type: LineType.success);
      return CommandResult.success('App launched');
    } else {
      shellService.addOutput('✗ Failed to launch application', type: LineType.error);
      return CommandResult.error('Launch failed');
    }
  }
}