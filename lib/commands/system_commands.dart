import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class HelpCommand extends BaseCommand {
  final Map<String, BaseCommand> commands;

  HelpCommand(this.commands);

  @override
  String get name => 'help';

  @override
  String get description => 'Show available commands';

  @override
  String get usage => 'help [command]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      shellService.addOutput('═' * 50);
      shellService.addOutput('AVAILABLE COMMANDS', type: LineType.info);
      shellService.addOutput('═' * 50);

      final sortedCommands = commands.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (var entry in sortedCommands) {
        shellService.addOutput('${entry.key.padRight(15)} - ${entry.value.description}');
      }

      shellService.addOutput('═' * 50);
      shellService.addOutput('Type "help <command>" for detailed usage', type: LineType.info);
    } else {
      final cmdName = args[0];
      final cmd = commands[cmdName];
      
      if (cmd == null) {
        shellService.addOutput('Unknown command: $cmdName', type: LineType.error);
        return CommandResult.error('Unknown command');
      }
      
      cmd.printHelp(shellService);
    }

    return CommandResult.success('Help displayed');
  }
}

class ClearCommand extends BaseCommand {
  @override
  String get name => 'clear';

  @override
  String get description => 'Clear terminal screen';

  @override
  String get usage => 'clear';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    shellService.clear();
    return CommandResult.success('Screen cleared');
  }
}

class StatusCommand extends BaseCommand {
  @override
  String get name => 'status';

  @override
  String get description => 'Show system status';

  @override
  String get usage => 'status';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    shellService.addOutput('Gathering system information...');
    shellService.addOutput('═' * 50);

    // Get storage info
    try {
      final appDir = await getApplicationDocumentsDirectory();
     // final stat = await appDir.stat();
      
      shellService.addOutput('SYSTEM STATUS', type: LineType.info);
      shellService.addOutput('═' * 50);
      shellService.addOutput('Platform: ${Platform.operatingSystem}');
      shellService.addOutput('Version: ${Platform.operatingSystemVersion}');
      shellService.addOutput('App Dir: ${appDir.path}');
      shellService.addOutput('');
      shellService.addOutput('Installed Apps: ${appService.installedApps.length}');
      shellService.addOutput('═' * 50);
    } catch (e) {
      shellService.addOutput('Error getting system info: $e', type: LineType.error);
    }

    return CommandResult.success('Status displayed');
  }
}

class PwdCommand extends BaseCommand {
  @override
  String get name => 'pwd';

  @override
  String get description => 'Print working directory';

  @override
  String get usage => 'pwd';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    shellService.addOutput(shellService.currentDirectory);
    return CommandResult.success(shellService.currentDirectory);
  }
}

class LsCommand extends BaseCommand {
  @override
  String get name => 'ls';

  @override
  String get description => 'List directory contents';

  @override
  String get usage => 'ls [path]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    try {
      final path = args.isEmpty ? shellService.currentDirectory : args[0];
      final dir = Directory(path);

      if (!await dir.exists()) {
        shellService.addOutput('Directory not found: $path', type: LineType.error);
        return CommandResult.error('Directory not found');
      }

      final entities = await dir.list().toList();
      
      if (entities.isEmpty) {
        shellService.addOutput('Empty directory');
        return CommandResult.success('Empty');
      }

      for (var entity in entities) {
        final name = entity.path.split('/').last;
        final isDir = entity is Directory;
        final prefix = isDir ? '📁 ' : '📄 ';
        shellService.addOutput('$prefix$name');
      }

      return CommandResult.success('Listed ${entities.length} items');
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class CdCommand extends BaseCommand {
  @override
  String get name => 'cd';

  @override
  String get description => 'Change directory';

  @override
  String get usage => 'cd <path>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      return await shellService.changeDirectory(appDir.path);
    }

    return await shellService.changeDirectory(args[0]);
  }
}

class CatCommand extends BaseCommand {
  @override
  String get name => 'cat';

  @override
  String get description => 'Display file contents';

  @override
  String get usage => 'cat <file>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No file specified');
    }

    try {
      final file = File(args[0]);
      
      if (!await file.exists()) {
        shellService.addOutput('File not found: ${args[0]}', type: LineType.error);
        return CommandResult.error('File not found');
      }

      final contents = await file.readAsString();
      shellService.addOutput(contents);
      
      return CommandResult.success('File displayed');
    } catch (e) {
      shellService.addOutput('Error reading file: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}