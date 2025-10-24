import 'dart:io';
import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../services/package_manager_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class PkgCommand extends BaseCommand {
  final PackageManagerService packageService;

  PkgCommand(this.packageService);

  @override
  String get name => 'pkg';

  @override
  String get description => 'Package manager (install, remove, list)';

  @override
  String get usage => 'pkg <install|remove|list> [package_name]';

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
      case 'install':
        if (args.length < 2) {
          shellService.addOutput('Usage: pkg install <package_name>', type: LineType.error);
          return CommandResult.error('No package specified');
        }
        return await _installPackage(args[1], shellService);

      case 'remove':
        if (args.length < 2) {
          shellService.addOutput('Usage: pkg remove <package_name>', type: LineType.error);
          return CommandResult.error('No package specified');
        }
        return await _removePackage(args[1], shellService);

      case 'list':
        return await _listPackages(shellService);

      default:
        shellService.addOutput('Unknown action: $action', type: LineType.error);
        printHelp(shellService);
        return CommandResult.error('Unknown action');
    }
  }

  Future<CommandResult> _installPackage(String packageName, ShellService shellService) async {
    shellService.addOutput('Installing $packageName...');
    final result = await packageService.installPackage(packageName);
    
    if (result.success) {
      shellService.addOutput(result.output, type: LineType.success);
    } else {
      shellService.addOutput(result.error ?? 'Installation failed', type: LineType.error);
    }
    
    return result;
  }

  Future<CommandResult> _removePackage(String packageName, ShellService shellService) async {
    shellService.addOutput('Removing $packageName...');
    final result = await packageService.removePackage(packageName);
    
    if (result.success) {
      shellService.addOutput(result.output, type: LineType.success);
    } else {
      shellService.addOutput(result.error ?? 'Removal failed', type: LineType.error);
    }
    
    return result;
  }

  Future<CommandResult> _listPackages(ShellService shellService) async {
    final packages = packageService.installedPackages;
    
    if (packages.isEmpty) {
      shellService.addOutput('No packages installed', type: LineType.info);
      return CommandResult.success('No packages');
    }

    shellService.addOutput('Installed packages:', type: LineType.info);
    shellService.addOutput('═' * 50);
    
    for (var entry in packages.entries) {
      shellService.addOutput('${entry.key} (installed: ${entry.value})');
    }
    
    shellService.addOutput('═' * 50);
    return CommandResult.success('Listed ${packages.length} packages');
  }
}

class GoCommand extends BaseCommand {
  final PackageManagerService packageService;

  GoCommand(this.packageService);

  @override
  String get name => 'go';

  @override
  String get description => 'Run Go commands (run, build, setup)';

  @override
  String get usage => 'go <run|build|setup> [file.go]';

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
      case 'setup':
        return await _setupGo(shellService);

      case 'run':
        if (args.length < 2) {
          shellService.addOutput('Usage: go run <file.go>', type: LineType.error);
          return CommandResult.error('No file specified');
        }
        return await _runGo(args[1], shellService);

      case 'build':
        if (args.length < 2) {
          shellService.addOutput('Usage: go build <file.go>', type: LineType.error);
          return CommandResult.error('No file specified');
        }
        return await _buildGo(args[1], shellService);

      case 'version':
        return await _checkGoVersion(shellService);

      default:
        shellService.addOutput('Unknown action: $action', type: LineType.error);
        printHelp(shellService);
        return CommandResult.error('Unknown action');
    }
  }

  Future<CommandResult> _setupGo(ShellService shellService) async {
    shellService.addOutput('Setting up Go environment...');
    final result = await packageService.setupGoEnvironment();
    
    if (result.success) {
      shellService.addOutput(result.output, type: LineType.success);
      shellService.addOutput('');
      shellService.addOutput('To use Go, you need to:', type: LineType.info);
      shellService.addOutput('1. Install Termux from F-Droid');
      shellService.addOutput('2. Run: pkg install golang');
      shellService.addOutput('3. Create your Go files in the go/src directory');
    } else {
      shellService.addOutput(result.error ?? 'Setup failed', type: LineType.error);
    }
    
    return result;
  }

  Future<CommandResult> _runGo(String filename, ShellService shellService) async {
    try {
      shellService.addOutput('Running Go file: $filename');
      
      final file = File(filename);
      if (!await file.exists()) {
        shellService.addOutput('File not found: $filename', type: LineType.error);
        return CommandResult.error('File not found');
      }

      final result = await Process.run('go', ['run', filename]);
      
      if (result.exitCode == 0) {
        shellService.addOutput(result.stdout.toString());
        return CommandResult.success('Execution completed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Execution failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      shellService.addOutput('');
      shellService.addOutput('Go is not installed. Options:', type: LineType.info);
      shellService.addOutput('1. Install Termux and run: pkg install golang');
      shellService.addOutput('2. Use an online Go compiler');
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _buildGo(String filename, ShellService shellService) async {
    try {
      shellService.addOutput('Building Go file: $filename');
      
      final file = File(filename);
      if (!await file.exists()) {
        shellService.addOutput('File not found: $filename', type: LineType.error);
        return CommandResult.error('File not found');
      }

      final outputName = filename.replaceAll('.go', '');
      final result = await Process.run('go', ['build', '-o', outputName, filename]);
      
      if (result.exitCode == 0) {
        shellService.addOutput('Build successful: $outputName', type: LineType.success);
        return CommandResult.success('Build completed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Build failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      shellService.addOutput('Go is not installed', type: LineType.warning);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _checkGoVersion(ShellService shellService) async {
    try {
      final result = await Process.run('go', ['version']);
      
      if (result.exitCode == 0) {
        shellService.addOutput(result.stdout.toString(), type: LineType.success);
        return CommandResult.success('Go installed');
      } else {
        shellService.addOutput('Go not found', type: LineType.warning);
        return CommandResult.error('Go not installed');
      }
    } catch (e) {
      shellService.addOutput('Go is not installed on this system', type: LineType.warning);
      return CommandResult.error('Not installed');
    }
  }
}