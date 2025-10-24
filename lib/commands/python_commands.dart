import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../services/package_manager_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class PythonCommand extends BaseCommand {
  final PackageManagerService packageService;

  PythonCommand(this.packageService);

  @override
  String get name => 'python';

  @override
  String get description => 'Run Python scripts and manage Python environment';

  @override
  String get usage => 'python <run|setup|install|version|pip> [args]';

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
        return await _setupPython(shellService);

      case 'run':
        if (args.length < 2) {
          shellService.addOutput('Usage: python run <file.py>', type: LineType.error);
          return CommandResult.error('No file specified');
        }
        return await _runPython(args[1], shellService);

      case 'install':
        if (args.length < 2) {
          shellService.addOutput('Usage: python install <package>', type: LineType.error);
          return CommandResult.error('No package specified');
        }
        return await _installPackage(args[1], shellService);

      case 'version':
        return await _checkPythonVersion(shellService);

      case 'pip':
        return await _runPip(args.sublist(1), shellService);

      default:
        shellService.addOutput('Unknown action: $action', type: LineType.error);
        printHelp(shellService);
        return CommandResult.error('Unknown action');
    }
  }

  Future<CommandResult> _setupPython(ShellService shellService) async {
    shellService.addOutput('Setting up Python environment...');
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pythonDir = Directory('${appDir.path}/python');
      
      if (!await pythonDir.exists()) {
        await pythonDir.create(recursive: true);
      }

      final scriptsDir = Directory('${pythonDir.path}/scripts');
      final packagesDir = Directory('${pythonDir.path}/packages');
      final projectsDir = Directory('${pythonDir.path}/projects');

      await Future.wait([
        scriptsDir.create(recursive: true),
        packagesDir.create(recursive: true),
        projectsDir.create(recursive: true),
      ]);

      shellService.addOutput('✓ Python environment created', type: LineType.success);
      shellService.addOutput('', type: LineType.info);
      shellService.addOutput('Python directories:', type: LineType.info);
      shellService.addOutput('  Scripts:  ${scriptsDir.path}');
      shellService.addOutput('  Packages: ${packagesDir.path}');
      shellService.addOutput('  Projects: ${projectsDir.path}');
      shellService.addOutput('');
      shellService.addOutput('To use Python:', type: LineType.info);
      shellService.addOutput('1. Install Termux from F-Droid');
      shellService.addOutput('2. Run: pkg install python');
      shellService.addOutput('3. Create .py files in python/scripts/');
      shellService.addOutput('4. Use: python run script.py');

      return CommandResult.success('Python environment set up');
    } catch (e) {
      shellService.addOutput('Error setting up Python: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _runPython(String filename, ShellService shellService) async {
    try {
      shellService.addOutput('Running Python script: $filename');
      
      final file = File(filename);
      if (!await file.exists()) {
        shellService.addOutput('File not found: $filename', type: LineType.error);
        return CommandResult.error('File not found');
      }

      final result = await Process.run('python3', [filename]);
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        if (output.isNotEmpty) {
          shellService.addOutput(output);
        }
        shellService.addOutput('✓ Script executed successfully', type: LineType.success);
        return CommandResult.success('Execution completed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Execution failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      shellService.addOutput('');
      shellService.addOutput('Python is not installed. Options:', type: LineType.info);
      shellService.addOutput('1. Install Termux and run: pkg install python');
      shellService.addOutput('2. Use an online Python interpreter');
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _installPackage(String packageName, ShellService shellService) async {
    try {
      shellService.addOutput('Installing Python package: $packageName');
      
      final result = await Process.run('pip3', ['install', packageName]);
      
      if (result.exitCode == 0) {
        shellService.addOutput('✓ Package installed successfully', type: LineType.success);
        return CommandResult.success('Package installed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Installation failed');
      }
    } catch (e) {
      shellService.addOutput('Error: pip3 not found', type: LineType.error);
      shellService.addOutput('Install Python first: python setup', type: LineType.info);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _checkPythonVersion(ShellService shellService) async {
    try {
      final result = await Process.run('python3', ['--version']);
      
      if (result.exitCode == 0) {
        shellService.addOutput(result.stdout.toString(), type: LineType.success);
        return CommandResult.success('Python installed');
      } else {
        shellService.addOutput('Python not found', type: LineType.warning);
        return CommandResult.error('Python not installed');
      }
    } catch (e) {
      shellService.addOutput('Python is not installed on this system', type: LineType.warning);
      shellService.addOutput('Run: python setup (for instructions)', type: LineType.info);
      return CommandResult.error('Not installed');
    }
  }

  Future<CommandResult> _runPip(List<String> args, ShellService shellService) async {
    if (args.isEmpty) {
      shellService.addOutput('Usage: python pip <command>', type: LineType.error);
      return CommandResult.error('No pip command');
    }

    try {
      final result = await Process.run('pip3', args);
      
      if (result.exitCode == 0) {
        shellService.addOutput(result.stdout.toString());
        return CommandResult.success('Pip command executed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Pip command failed');
      }
    } catch (e) {
      shellService.addOutput('Error: pip3 not found', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}