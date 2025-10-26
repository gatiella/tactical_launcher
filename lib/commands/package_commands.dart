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
  String get description =>
      'Package manager (install, remove, list, search, update)';

  @override
  String get usage =>
      'pkg <install|remove|list|search|update|upgrade> [package_name]';

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
      case 'i':
        if (args.length < 2) {
          shellService.addOutput(
            'Usage: pkg install <package_name>',
            type: LineType.error,
          );
          return CommandResult.error('No package specified');
        }
        return await _installPackage(args[1], shellService);

      case 'remove':
      case 'uninstall':
      case 'rm':
        if (args.length < 2) {
          shellService.addOutput(
            'Usage: pkg remove <package_name>',
            type: LineType.error,
          );
          return CommandResult.error('No package specified');
        }
        return await _removePackage(args[1], shellService);

      case 'list':
      case 'ls':
        return await _listPackages(shellService);

      case 'search':
        if (args.length < 2) {
          shellService.addOutput(
            'Usage: pkg search <query>',
            type: LineType.error,
          );
          return CommandResult.error('No search query');
        }
        return await _searchPackages(args[1], shellService);

      case 'update':
        return await _updatePackageLists(shellService);

      case 'upgrade':
        return await _upgradePackages(shellService);

      case 'setup-termux':
        return await _setupTermuxEnvironment(shellService);

      case 'setup-proot':
        return await _setupProot(shellService);

      case 'info':
        if (args.length < 2) {
          shellService.addOutput(
            'Usage: pkg info <package_name>',
            type: LineType.error,
          );
          return CommandResult.error('No package specified');
        }
        return await _showPackageInfo(args[1], shellService);

      default:
        shellService.addOutput('Unknown action: $action', type: LineType.error);
        printHelp(shellService);
        return CommandResult.error('Unknown action');
    }
  }

  Future<CommandResult> _installPackage(
    String packageName,
    ShellService shellService,
  ) async {
    shellService.addOutput('Installing $packageName...', type: LineType.info);
    shellService.addOutput('═' * 50);

    final result = await packageService.installPackage(packageName);

    if (result.success) {
      shellService.addOutput('✓ ${result.output}', type: LineType.success);
      shellService.addOutput('');
      shellService.addOutput(
        'Package installed successfully!',
        type: LineType.success,
      );

      // Show additional info
      final binPath = '${packageService.binDir}/$packageName';
      final binFile = File(binPath);
      if (await binFile.exists()) {
        shellService.addOutput('Binary location: $binPath');
        shellService.addOutput('Run with: $packageName or ./$packageName');
      }
    } else {
      shellService.addOutput(
        '✗ ${result.error ?? "Installation failed"}',
        type: LineType.error,
      );
      shellService.addOutput('');
      _showInstallationHelp(shellService, packageName);
    }

    shellService.addOutput('═' * 50);
    return result;
  }

  void _showInstallationHelp(ShellService shellService, String packageName) {
    shellService.addOutput('Installation options:', type: LineType.info);
    shellService.addOutput('');
    shellService.addOutput('1. Install via Termux (recommended):');
    shellService.addOutput('   - Install Termux from F-Droid');
    shellService.addOutput('   - Run: pkg install $packageName');
    shellService.addOutput('   - Then use "pkg setup-termux" in this app');
    shellService.addOutput('');
    shellService.addOutput('2. Setup proot environment:');
    shellService.addOutput('   - Run: pkg setup-proot');
    shellService.addOutput('   - Then: proot apt-get install $packageName');
    shellService.addOutput('');
    shellService.addOutput('3. Manual installation:');
    shellService.addOutput('   - Download binary for your architecture');
    shellService.addOutput('   - Place in: ${packageService.binDir}');
    shellService.addOutput(
      '   - Run: chmod 755 ${packageService.binDir}/$packageName',
    );
  }

  Future<CommandResult> _removePackage(
    String packageName,
    ShellService shellService,
  ) async {
    shellService.addOutput('Removing $packageName...', type: LineType.warning);
    final result = await packageService.removePackage(packageName);

    if (result.success) {
      shellService.addOutput('✓ ${result.output}', type: LineType.success);
    } else {
      shellService.addOutput(
        '✗ ${result.error ?? "Removal failed"}',
        type: LineType.error,
      );
    }

    return result;
  }

  Future<CommandResult> _listPackages(ShellService shellService) async {
    final packages = packageService.installedPackages;

    if (packages.isEmpty) {
      shellService.addOutput('No packages installed', type: LineType.info);
      shellService.addOutput('');
      shellService.addOutput(
        'Install packages with: pkg install <package_name>',
      );
      shellService.addOutput(
        'Available: git, python, node, vim, nano, curl, wget, etc.',
      );
      return CommandResult.success('No packages');
    }

    shellService.addOutput('Installed packages:', type: LineType.info);
    shellService.addOutput('═' * 50);

    for (var entry in packages.entries) {
      shellService.addOutput('📦 ${entry.key.padRight(20)} v${entry.value}');
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('Total: ${packages.length} package(s)');
    return CommandResult.success('Listed ${packages.length} packages');
  }

  Future<CommandResult> _searchPackages(
    String query,
    ShellService shellService,
  ) async {
    shellService.addOutput('Searching for: $query', type: LineType.info);
    shellService.addOutput('═' * 50);

    final results = await packageService.searchPackages(query);

    if (results.isEmpty) {
      shellService.addOutput(
        'No packages found matching: $query',
        type: LineType.warning,
      );
      return CommandResult.error('No matches');
    }

    shellService.addOutput(
      'Found ${results.length} package(s):',
      type: LineType.success,
    );
    shellService.addOutput('');

    for (var pkg in results) {
      final installed = packageService.installedPackages.containsKey(pkg);
      final status = installed ? '✓ installed' : '  available';
      shellService.addOutput('$status  $pkg');
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('Install with: pkg install <package_name>');
    return CommandResult.success('Found ${results.length} packages');
  }

  Future<CommandResult> _updatePackageLists(ShellService shellService) async {
    shellService.addOutput('Updating package lists...', type: LineType.info);
    final result = await packageService.updatePackageLists();

    if (result.success) {
      shellService.addOutput('✓ ${result.output}', type: LineType.success);
    } else {
      shellService.addOutput('✗ ${result.error}', type: LineType.error);
    }

    return result;
  }

  Future<CommandResult> _upgradePackages(ShellService shellService) async {
    shellService.addOutput('Upgrading packages...', type: LineType.info);
    shellService.addOutput('This will upgrade all installed packages.');
    shellService.addOutput('');

    final packages = packageService.installedPackages;
    if (packages.isEmpty) {
      shellService.addOutput('No packages to upgrade', type: LineType.warning);
      return CommandResult.success('Nothing to do');
    }

    shellService.addOutput('Not yet implemented');
    shellService.addOutput(
      'Manual upgrade: pkg remove <name> && pkg install <name>',
    );
    return CommandResult.success('Upgrade info shown');
  }

  Future<CommandResult> _setupTermuxEnvironment(
    ShellService shellService,
  ) async {
    shellService.addOutput(
      'Setting up Termux integration...',
      type: LineType.info,
    );
    shellService.addOutput('═' * 50);
    shellService.addOutput('');
    shellService.addOutput('To use Termux with this app:', type: LineType.info);
    shellService.addOutput('');
    shellService.addOutput('1. Install Termux from F-Droid (NOT Play Store)');
    shellService.addOutput(
      '   Download: https://f-droid.org/packages/com.termux/',
    );
    shellService.addOutput('');
    shellService.addOutput('2. Open Termux and run:');
    shellService.addOutput('   pkg update && pkg upgrade');
    shellService.addOutput('');
    shellService.addOutput('3. Install desired packages in Termux:');
    shellService.addOutput('   pkg install git python nodejs vim nano');
    shellService.addOutput('');
    shellService.addOutput('4. Binaries will be available at:');
    shellService.addOutput('   /data/data/com.termux/files/usr/bin/');
    shellService.addOutput('');
    shellService.addOutput('5. Use them in this app with full paths or:');
    shellService.addOutput('   pkg install <name> (will copy from Termux)');
    shellService.addOutput('═' * 50);

    return CommandResult.success('Instructions shown');
  }

  Future<CommandResult> _setupProot(ShellService shellService) async {
    shellService.addOutput(
      'Setting up proot environment...',
      type: LineType.info,
    );
    final result = await packageService.setupProotEnvironment();

    if (result.success) {
      shellService.addOutput('✓ ${result.output}', type: LineType.success);
      shellService.addOutput('');
      shellService.addOutput('Proot allows running Linux binaries on Android');
      shellService.addOutput(
        'Use: proot -r ${packageService.prootDir} /bin/sh',
      );
    } else {
      shellService.addOutput('✗ ${result.error}', type: LineType.error);
    }

    return result;
  }

  Future<CommandResult> _showPackageInfo(
    String packageName,
    ShellService shellService,
  ) async {
    final packages = packageService.installedPackages;

    if (!packages.containsKey(packageName)) {
      shellService.addOutput(
        'Package not installed: $packageName',
        type: LineType.error,
      );
      return CommandResult.error('Not installed');
    }

    shellService.addOutput('Package information:', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('Name:    $packageName');
    shellService.addOutput('Version: ${packages[packageName]}');

    final binPath = '${packageService.binDir}/$packageName';
    final binFile = File(binPath);
    if (await binFile.exists()) {
      final stat = await binFile.stat();
      shellService.addOutput(
        'Size:    ${(stat.size / 1024).toStringAsFixed(2)} KB',
      );
      shellService.addOutput('Path:    $binPath');
    }

    shellService.addOutput('═' * 50);
    return CommandResult.success('Info shown');
  }

  @override
  void printHelp(ShellService shellService) {
    shellService.addOutput('Package Manager Commands:', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('pkg install <name>     Install a package');
    shellService.addOutput('pkg remove <name>      Remove a package');
    shellService.addOutput('pkg list               List installed packages');
    shellService.addOutput('pkg search <query>     Search for packages');
    shellService.addOutput('pkg update             Update package lists');
    shellService.addOutput('pkg upgrade            Upgrade all packages');
    shellService.addOutput('pkg info <name>        Show package info');
    shellService.addOutput('pkg setup-termux       Setup Termux integration');
    shellService.addOutput('pkg setup-proot        Setup proot environment');
    shellService.addOutput('═' * 50);
  }
}

// Proot command for running commands in isolated environment
class ProotCommand extends BaseCommand {
  final PackageManagerService packageService;

  ProotCommand(this.packageService);

  @override
  String get name => 'proot';

  @override
  String get description => 'Run commands in proot environment';

  @override
  String get usage => 'proot <command>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      shellService.addOutput('Usage: proot <command>', type: LineType.error);
      shellService.addOutput('Example: proot apt-get install vim');
      return CommandResult.error('No command specified');
    }

    final command = args.join(' ');
    shellService.addOutput('Executing in proot: $command', type: LineType.info);

    final result = await packageService.executeInProot(command);

    if (result.success) {
      shellService.addOutput(result.output);
    } else {
      shellService.addOutput(
        result.error ?? 'Execution failed',
        type: LineType.error,
      );
    }

    return result;
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
          shellService.addOutput(
            'Usage: go run <file.go>',
            type: LineType.error,
          );
          return CommandResult.error('No file specified');
        }
        return await _runGo(args[1], shellService);

      case 'build':
        if (args.length < 2) {
          shellService.addOutput(
            'Usage: go build <file.go>',
            type: LineType.error,
          );
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
    shellService.addOutput('Setting up Go environment...', type: LineType.info);
    final result = await packageService.setupGoEnvironment();

    if (result.success) {
      shellService.addOutput(result.output, type: LineType.success);
      shellService.addOutput('');
      shellService.addOutput('To install Go:', type: LineType.info);
      shellService.addOutput('1. Via Termux: pkg install golang');
      shellService.addOutput('2. Via pkg manager: pkg install go');
      shellService.addOutput('3. Manual: Download from https://go.dev/dl/');
    } else {
      shellService.addOutput(
        result.error ?? 'Setup failed',
        type: LineType.error,
      );
    }

    return result;
  }

  Future<CommandResult> _runGo(
    String filename,
    ShellService shellService,
  ) async {
    try {
      shellService.addOutput('Running Go file: $filename');

      final file = File(filename);
      if (!await file.exists()) {
        shellService.addOutput(
          'File not found: $filename',
          type: LineType.error,
        );
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
      shellService.addOutput(
        'Go is not installed. Install with:',
        type: LineType.info,
      );
      shellService.addOutput('  pkg install go');
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _buildGo(
    String filename,
    ShellService shellService,
  ) async {
    try {
      shellService.addOutput('Building Go file: $filename');

      final file = File(filename);
      if (!await file.exists()) {
        shellService.addOutput(
          'File not found: $filename',
          type: LineType.error,
        );
        return CommandResult.error('File not found');
      }

      final outputName = filename.replaceAll('.go', '');
      final result = await Process.run('go', [
        'build',
        '-o',
        outputName,
        filename,
      ]);

      if (result.exitCode == 0) {
        shellService.addOutput(
          'Build successful: $outputName',
          type: LineType.success,
        );
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
        shellService.addOutput(
          result.stdout.toString(),
          type: LineType.success,
        );
        return CommandResult.success('Go installed');
      } else {
        shellService.addOutput('Go not found', type: LineType.warning);
        return CommandResult.error('Go not installed');
      }
    } catch (e) {
      shellService.addOutput(
        'Go is not installed on this system',
        type: LineType.warning,
      );
      shellService.addOutput('Install with: pkg install go');
      return CommandResult.error('Not installed');
    }
  }
}

// AptGet command for Debian/Ubuntu style package management
class AptGetCommand extends BaseCommand {
  final PackageManagerService packageService;

  AptGetCommand(this.packageService);

  @override
  String get name => 'apt-get';

  @override
  String get description => 'APT package manager (requires proot)';

  @override
  String get usage => 'apt-get <install|remove|update|upgrade> [package]';

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
    final packageName = args.length > 1 ? args[1] : null;

    // Check if apt-get is available
    try {
      final whichResult = await Process.run('which', ['apt-get']);
      if (whichResult.exitCode != 0) {
        shellService.addOutput('apt-get not found', type: LineType.error);
        shellService.addOutput('');
        shellService.addOutput('To use apt-get:', type: LineType.info);
        shellService.addOutput('1. Setup proot: pkg setup-proot');
        shellService.addOutput('2. Or install Termux with proot-distro');
        shellService.addOutput('3. Then use: proot apt-get $action');
        return CommandResult.error('apt-get not available');
      }
    } catch (e) {
      return await _executeViaRoot(action, packageName, shellService);
    }

    // Execute apt-get command
    try {
      final cmdArgs = [action];
      if (packageName != null) cmdArgs.add(packageName);
      if (action == 'install' || action == 'remove') {
        cmdArgs.insert(0, '-y'); // Auto-yes
      }

      shellService.addOutput(
        'Running: apt-get ${cmdArgs.join(" ")}',
        type: LineType.info,
      );

      final result = await Process.run(
        'apt-get',
        cmdArgs,
        environment: {'DEBIAN_FRONTEND': 'noninteractive'},
      );

      shellService.addOutput(result.stdout.toString());
      if (result.stderr.toString().isNotEmpty) {
        shellService.addOutput(
          result.stderr.toString(),
          type: LineType.warning,
        );
      }

      if (result.exitCode == 0) {
        return CommandResult.success('Command completed');
      } else {
        return CommandResult.error('Command failed', exitCode: result.exitCode);
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _executeViaRoot(
    String action,
    String? packageName,
    ShellService shellService,
  ) async {
    shellService.addOutput(
      'Attempting to run via proot...',
      type: LineType.info,
    );

    final command = packageName != null
        ? 'apt-get $action -y $packageName'
        : 'apt-get $action';

    return await packageService.executeInProot(command);
  }

  @override
  void printHelp(ShellService shellService) {
    shellService.addOutput('APT Package Manager:', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('apt-get update         Update package lists');
    shellService.addOutput('apt-get upgrade        Upgrade all packages');
    shellService.addOutput('apt-get install <n> Install package');
    shellService.addOutput('apt-get remove <n>  Remove package');
    shellService.addOutput('═' * 50);
    shellService.addOutput('Note: Requires proot environment');
  }
}
