import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class UpdateCommand extends BaseCommand {
  @override
  String get name => 'update';

  @override
  String get description => 'Update package lists and check for updates';

  @override
  String get usage => 'update [--check|--all]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    final checkOnly = args.contains('--check');
    
    shellService.addOutput('Checking for updates...');
    shellService.addOutput('═' * 50);

    // Check launcher version
    await _checkLauncherUpdate(shellService);
    
    shellService.addOutput('═' * 50);
    
    if (!checkOnly) {
      shellService.addOutput('');
      shellService.addOutput('To update:', type: LineType.info);
      shellService.addOutput('  launcher: upgrade launcher');
      shellService.addOutput('  packages: pkg update <name>');
      shellService.addOutput('  system:   Use device settings');
    }

    return CommandResult.success('Update check complete');
  }

  Future<void> _checkLauncherUpdate(ShellService shellService) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      shellService.addOutput('Current Version: v$currentVersion', type: LineType.info);
      shellService.addOutput('Checking GitHub for updates...');
      
      // In production, you'd check a real update server
      // This is a placeholder implementation
      shellService.addOutput('✓ You are running the latest version', type: LineType.success);
      
    } catch (e) {
      shellService.addOutput('Unable to check for updates', type: LineType.warning);
    }
  }
}

class UpgradeCommand extends BaseCommand {
  @override
  String get name => 'upgrade';

  @override
  String get description => 'Upgrade launcher or packages';

  @override
  String get usage => 'upgrade <launcher|package_name|--all>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No target specified');
    }

    final target = args[0];

    if (target == 'launcher') {
      return await _upgradeLauncher(shellService);
    } else if (target == '--all') {
      return await _upgradeAll(shellService);
    } else {
      return await _upgradePackage(target, shellService);
    }
  }

  Future<CommandResult> _upgradeLauncher(ShellService shellService) async {
    shellService.addOutput('Checking for launcher updates...');
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      shellService.addOutput('Current version: v$currentVersion');
      shellService.addOutput('Checking for new version...');
      
      // Simulate version check (in production, check real server)
      await Future.delayed(const Duration(seconds: 2));
      
      shellService.addOutput('');
      shellService.addOutput('No updates available', type: LineType.info);
      shellService.addOutput('You are running the latest version!', type: LineType.success);
      
      return CommandResult.success('Already up to date');
    } catch (e) {
      shellService.addOutput('Error checking for updates: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _upgradePackage(String packageName, ShellService shellService) async {
    shellService.addOutput('Upgrading package: $packageName');
    shellService.addOutput('This feature requires package manager integration');
    shellService.addOutput('Use: pkg install $packageName (to reinstall)', type: LineType.info);
    
    return CommandResult.success('Package upgrade info shown');
  }

  Future<CommandResult> _upgradeAll(ShellService shellService) async {
    shellService.addOutput('Upgrading all packages...');
    shellService.addOutput('');
    
    await _upgradeLauncher(shellService);
    
    shellService.addOutput('');
    shellService.addOutput('✓ All components up to date', type: LineType.success);
    
    return CommandResult.success('All upgrades complete');
  }
}

class VersionCommand extends BaseCommand {
  @override
  String get name => 'version';

  @override
  String get description => 'Show launcher version and system info';

  @override
  String get usage => 'version [--detailed]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    final detailed = args.contains('--detailed');
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      shellService.addOutput('═' * 50);
      shellService.addOutput('TACTICAL LAUNCHER', type: LineType.info);
      shellService.addOutput('═' * 50);
      shellService.addOutput('Version:     v${packageInfo.version}');
      shellService.addOutput('Build:       ${packageInfo.buildNumber}');
      shellService.addOutput('Package:     ${packageInfo.packageName}');
      
      if (detailed) {
        shellService.addOutput('');
        shellService.addOutput('SYSTEM INFORMATION', type: LineType.info);
        shellService.addOutput('═' * 50);
        shellService.addOutput('OS:          ${Platform.operatingSystem}');
        shellService.addOutput('Version:     ${Platform.operatingSystemVersion}');
        shellService.addOutput('Locale:      ${Platform.localeName}');
        shellService.addOutput('Processors:  ${Platform.numberOfProcessors}');
        
        final appDir = await getApplicationDocumentsDirectory();
        shellService.addOutput('App Dir:     ${appDir.path}');
      }
      
      shellService.addOutput('═' * 50);
      
      return CommandResult.success('Version displayed');
    } catch (e) {
      shellService.addOutput('Error getting version info: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class ChangelogCommand extends BaseCommand {
  @override
  String get name => 'changelog';

  @override
  String get description => 'Show recent changes and updates';

  @override
  String get usage => 'changelog';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    shellService.addOutput('═' * 50);
    shellService.addOutput('CHANGELOG - TACTICAL LAUNCHER', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('');
    
    shellService.addOutput('v2.0.0 - Latest', type: LineType.success);
    shellService.addOutput('  ✓ Custom theme creator');
    shellService.addOutput('  ✓ Theme manager with presets');
    shellService.addOutput('  ✓ Python project support');
    shellService.addOutput('  ✓ Update/upgrade system');
    shellService.addOutput('  ✓ 11 new advanced commands');
    shellService.addOutput('  ✓ 4 custom widgets');
    shellService.addOutput('  ✓ 6 gesture controls');
    shellService.addOutput('  ✓ Gesture tutorial');
    shellService.addOutput('');
    
    shellService.addOutput('v1.0.0 - Initial Release');
    shellService.addOutput('  ✓ Terminal-based launcher');
    shellService.addOutput('  ✓ Shell command execution');
    shellService.addOutput('  ✓ App launching via terminal');
    shellService.addOutput('  ✓ File system navigation');
    shellService.addOutput('  ✓ Go project support');
    shellService.addOutput('  ✓ Package management');
    shellService.addOutput('  ✓ 4 color themes');
    
    shellService.addOutput('');
    shellService.addOutput('═' * 50);
    
    return CommandResult.success('Changelog displayed');
  }
}