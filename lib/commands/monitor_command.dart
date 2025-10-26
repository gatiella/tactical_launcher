import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class MonitorCommand extends BaseCommand {
  @override
  String get name => 'monitor';

  @override
  String get description => 'System resource monitor and performance graph';

  @override
  String get usage => 'monitor [--graph|--list|--cpu|--memory|--battery]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    try {
      if (args.isEmpty) {
        return await _showAllStats(shellService, appService);
      }

      switch (args[0]) {
        case '--graph':
          shellService.addOutput(
            '✓ Graph view enabled',
            type: LineType.success,
          );
          shellService.addOutput(
            'Swipe up to see widgets',
            type: LineType.info,
          );
          return CommandResult.success('TOGGLE_GRAPH:true');

        case '--list':
          shellService.addOutput('✓ List view enabled', type: LineType.success);
          return CommandResult.success('TOGGLE_GRAPH:false');

        case '--cpu':
          return await _showCPUInfo(shellService);

        case '--memory':
          return await _showMemoryInfo(shellService);

        case '--battery':
          return await _showBatteryInfo(shellService);

        case '--all':
          return await _showAllStats(shellService, appService);

        default:
          shellService.addOutput(
            'Unknown option: ${args[0]}',
            type: LineType.warning,
          );
          shellService.addOutput('Usage: $usage', type: LineType.info);
          return await _showAllStats(shellService, appService);
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _showAllStats(
    ShellService shellService,
    AppManagerService appService,
  ) async {
    shellService.addOutput('═' * 50);
    shellService.addOutput('SYSTEM MONITOR', type: LineType.info);
    shellService.addOutput('═' * 50);

    // Platform info
    shellService.addOutput('📱 Platform:', type: LineType.success);
    shellService.addOutput('  OS: ${Platform.operatingSystem}');
    shellService.addOutput('  Version: ${Platform.operatingSystemVersion}');
    shellService.addOutput('  Processors: ${Platform.numberOfProcessors}');
    shellService.addOutput('');

    // Battery info
    try {
      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;
      final batteryState = await battery.batteryState;

      final batteryIcon = _getBatteryIcon(batteryLevel);
      final stateIcon = _getBatteryStateIcon(batteryState);

      shellService.addOutput('🔋 Battery:', type: LineType.success);
      shellService.addOutput('  Level: $batteryIcon $batteryLevel%');
      shellService.addOutput('  State: $stateIcon ${batteryState.name}');

      // Battery health indicator
      if (batteryLevel >= 80) {
        shellService.addOutput('  Health: Excellent ✓', type: LineType.success);
      } else if (batteryLevel >= 50) {
        shellService.addOutput('  Health: Good ✓', type: LineType.success);
      } else if (batteryLevel >= 20) {
        shellService.addOutput('  Health: Low ⚠', type: LineType.warning);
      } else {
        shellService.addOutput('  Health: Critical ⚠', type: LineType.error);
      }

      shellService.addOutput('');
    } catch (e) {
      shellService.addOutput(
        '🔋 Battery: Not available',
        type: LineType.warning,
      );
      shellService.addOutput('');
    }

    // App stats
    shellService.addOutput('📦 Applications:', type: LineType.success);
    shellService.addOutput('  Installed: ${appService.installedApps.length}');
    shellService.addOutput('  Loading: ${appService.isLoading ? "Yes" : "No"}');
    shellService.addOutput('');

    // Memory info (basic)
    shellService.addOutput('💾 Memory:', type: LineType.success);
    shellService.addOutput('  Android limits memory access');
    shellService.addOutput('  Use: monitor --memory for details');
    shellService.addOutput('');

    shellService.addOutput('═' * 50);
    shellService.addOutput('Available Options:', type: LineType.info);
    shellService.addOutput('  monitor --graph    Toggle graph widget');
    shellService.addOutput('  monitor --list     Toggle list view');
    shellService.addOutput('  monitor --cpu      CPU information');
    shellService.addOutput('  monitor --memory   Memory details');
    shellService.addOutput('  monitor --battery  Battery details');
    shellService.addOutput('  monitor --all      Show all stats');
    shellService.addOutput('═' * 50);

    return CommandResult.success('System stats displayed');
  }

  Future<CommandResult> _showCPUInfo(ShellService shellService) async {
    shellService.addOutput('═' * 50);
    shellService.addOutput('CPU INFORMATION', type: LineType.info);
    shellService.addOutput('═' * 50);

    shellService.addOutput('🖥️  Processor Details:', type: LineType.success);
    shellService.addOutput('  Cores: ${Platform.numberOfProcessors}');
    shellService.addOutput('  Platform: ${Platform.operatingSystem}');
    shellService.addOutput('  Version: ${Platform.operatingSystemVersion}');
    shellService.addOutput('');

    // Try to get CPU info from /proc/cpuinfo (may not work on all devices)
    try {
      final cpuInfo = File('/proc/cpuinfo');
      if (await cpuInfo.exists()) {
        final contents = await cpuInfo.readAsString();
        final lines = contents.split('\n');

        // Extract processor name
        final processorLine = lines.firstWhere(
          (line) =>
              line.startsWith('Processor') || line.startsWith('model name'),
          orElse: () => '',
        );

        if (processorLine.isNotEmpty) {
          shellService.addOutput(
            '  Info: ${processorLine.split(':').last.trim()}',
          );
        }
      }
    } catch (e) {
      shellService.addOutput(
        '  Detailed info: Requires root access',
        type: LineType.warning,
      );
    }

    shellService.addOutput('');
    shellService.addOutput(
      'Note: Android restricts CPU monitoring',
      type: LineType.info,
    );
    shellService.addOutput(
      '      Root access required for detailed stats',
      type: LineType.info,
    );
    shellService.addOutput('═' * 50);

    return CommandResult.success('CPU info displayed');
  }

  Future<CommandResult> _showMemoryInfo(ShellService shellService) async {
    shellService.addOutput('═' * 50);
    shellService.addOutput('MEMORY INFORMATION', type: LineType.info);
    shellService.addOutput('═' * 50);

    shellService.addOutput('💾 System Memory:', type: LineType.success);
    shellService.addOutput(
      '  Platform: Android ${Platform.operatingSystemVersion}',
    );
    shellService.addOutput('');

    // Try to read memory info (may require permissions)
    try {
      final memInfo = File('/proc/meminfo');
      if (await memInfo.exists()) {
        final contents = await memInfo.readAsString();
        final lines = contents.split('\n');

        for (var line in lines.take(5)) {
          if (line.isNotEmpty) {
            shellService.addOutput('  $line');
          }
        }
        shellService.addOutput('');
      }
    } catch (e) {
      shellService.addOutput(
        '  RAM: Information restricted',
        type: LineType.warning,
      );
      shellService.addOutput(
        '  Swap: Information restricted',
        type: LineType.warning,
      );
      shellService.addOutput('');
    }

    shellService.addOutput(
      'Note: Android limits memory access',
      type: LineType.info,
    );
    shellService.addOutput(
      '      Use Settings > About Phone for details',
      type: LineType.info,
    );
    shellService.addOutput(
      '      Or install Termux for detailed stats',
      type: LineType.info,
    );
    shellService.addOutput('═' * 50);

    return CommandResult.success('Memory info displayed');
  }

  Future<CommandResult> _showBatteryInfo(ShellService shellService) async {
    try {
      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;
      final batteryState = await battery.batteryState;

      shellService.addOutput('═' * 50);
      shellService.addOutput('BATTERY INFORMATION', type: LineType.info);
      shellService.addOutput('═' * 50);

      final icon = _getBatteryIcon(batteryLevel);
      final stateIcon = _getBatteryStateIcon(batteryState);

      shellService.addOutput('🔋 Current Status:', type: LineType.success);
      shellService.addOutput('');
      shellService.addOutput('  Level:     $icon $batteryLevel%');
      shellService.addOutput('  State:     $stateIcon ${batteryState.name}');
      shellService.addOutput('');

      // Battery health indicator with more detail
      shellService.addOutput('📊 Health Assessment:', type: LineType.info);
      if (batteryLevel >= 90) {
        shellService.addOutput('  Status: Excellent ✓', type: LineType.success);
        shellService.addOutput('  Action: No action needed');
      } else if (batteryLevel >= 70) {
        shellService.addOutput('  Status: Very Good ✓', type: LineType.success);
        shellService.addOutput('  Action: No action needed');
      } else if (batteryLevel >= 50) {
        shellService.addOutput('  Status: Good ✓', type: LineType.success);
        shellService.addOutput('  Action: Continue normal use');
      } else if (batteryLevel >= 30) {
        shellService.addOutput('  Status: Moderate ⚠', type: LineType.warning);
        shellService.addOutput('  Action: Consider charging soon');
      } else if (batteryLevel >= 15) {
        shellService.addOutput('  Status: Low ⚠', type: LineType.warning);
        shellService.addOutput('  Action: Charge device soon');
      } else {
        shellService.addOutput('  Status: Critical ⚠⚠', type: LineType.error);
        shellService.addOutput('  Action: Charge immediately!');
      }

      shellService.addOutput('');

      // Charging info
      if (batteryState == BatteryState.charging) {
        shellService.addOutput(
          '⚡ Charging in progress',
          type: LineType.success,
        );
        final estimatedTime = _estimateChargingTime(batteryLevel);
        shellService.addOutput('  Estimated time to full: ~$estimatedTime min');
      } else if (batteryState == BatteryState.full) {
        shellService.addOutput(
          '✓ Battery fully charged',
          type: LineType.success,
        );
        shellService.addOutput('  Unplug to preserve battery health');
      } else if (batteryState == BatteryState.discharging) {
        shellService.addOutput('▼ Battery discharging', type: LineType.info);
        final estimatedTime = _estimateBatteryLife(batteryLevel);
        shellService.addOutput(
          '  Estimated time remaining: ~$estimatedTime min',
        );
      }

      shellService.addOutput('');
      shellService.addOutput('═' * 50);

      return CommandResult.success('Battery info displayed');
    } catch (e) {
      shellService.addOutput('═' * 50);
      shellService.addOutput('BATTERY INFORMATION', type: LineType.info);
      shellService.addOutput('═' * 50);
      shellService.addOutput(
        '❌ Battery information not available',
        type: LineType.error,
      );
      shellService.addOutput(
        '   This device may not support battery monitoring',
        type: LineType.warning,
      );
      shellService.addOutput('═' * 50);
      return CommandResult.error('Battery unavailable');
    }
  }

  // Helper methods for battery visualization
  String _getBatteryIcon(int level) {
    if (level >= 90) return '█████';
    if (level >= 70) return '████░';
    if (level >= 50) return '███░░';
    if (level >= 30) return '██░░░';
    if (level >= 10) return '█░░░░';
    return '░░░░░';
  }

  String _getBatteryStateIcon(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return '⚡';
      case BatteryState.full:
        return '✓';
      case BatteryState.discharging:
        return '▼';
      case BatteryState.connectedNotCharging:
        return '⏸';
      default:
        return '?';
    }
  }

  int _estimateChargingTime(int currentLevel) {
    // Rough estimate: 100-current level * 1.5 minutes per percent
    final remaining = 100 - currentLevel;
    return (remaining * 1.5).round();
  }

  int _estimateBatteryLife(int currentLevel) {
    // Rough estimate: current level * 3 minutes per percent under normal use
    return (currentLevel * 3).round();
  }
}
