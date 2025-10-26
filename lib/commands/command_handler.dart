import 'dart:io';

import 'package:tactical_launcher/commands/fix_command.dart';
import 'package:tactical_launcher/commands/storage_command.dart';
import 'package:tactical_launcher/commands/storage_setup_command.dart';
import 'package:tactical_launcher/models/terminal_line.dart';

import 'base_command.dart';
import 'app_commands.dart';
import 'system_commands.dart';
import 'package_commands.dart';
import 'advanced_commands.dart';
import 'python_commands.dart';
import 'update_commands.dart';
import 'ssh_commands.dart';
import 'backup_commands.dart';
import 'macro_commands.dart';
import 'git_commands.dart';
import 'monitor_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../services/package_manager_service.dart';
import '../services/ssh_service.dart';
import '../services/backup_service.dart';
import '../services/macro_service.dart';
import '../models/command_result.dart';
import '../screens/nano_editor_screen.dart';
import 'package:flutter/material.dart';

class CommandHandler {
  late final Map<String, BaseCommand> _commands;
  final PackageManagerService _packageService = PackageManagerService();
  final SSHService _sshService = SSHService();
  final BackupService _backupService = BackupService();
  final MacroService _macroService = MacroService();

  CommandHandler() {
    _commands = {
      // System commands
      'help': HelpCommand({}),
      'clear': ClearCommand(),
      'status': StatusCommand(),
      'pwd': PwdCommand(),
      'ls': LsCommand(),
      'cd': CdCommand(),
      'cat': CatCommand(),

      // App commands
      'apps': AppsCommand(),
      'search': SearchCommand(),
      'open': OpenCommand(),

      // Package management - ENHANCED
      'pkg': PkgCommand(_packageService),
      'apt-get': AptGetCommand(_packageService),
      'apt': AptGetCommand(_packageService), // Alias for apt-get
      'proot': ProotCommand(_packageService),

      // Language support
      'go': GoCommand(_packageService),
      'python': PythonCommand(_packageService),

      // Advanced file operations
      'mkdir': MkdirCommand(),
      'rm': RmCommand(),
      'cp': CpCommand(),
      'mv': MvCommand(),
      'touch': TouchCommand(),
      'echo': EchoCommand(),
      'grep': GrepCommand(),

      // Network commands
      'ping': PingCommand(),
      'wget': WgetCommand(),

      // Process management
      'ps': PsCommand(),

      // Text editor
      'nano': NanoCommand(),

      // Update system
      'update': UpdateCommand(),
      'upgrade': UpgradeCommand(),
      'version': VersionCommand(),
      'changelog': ChangelogCommand(),

      // SSH
      'ssh': SSHCommand(_sshService),

      // Backup
      'backup': BackupCommand(_backupService),

      // Macros
      'macro': MacroCommand(_macroService),

      // Git
      'git': GitCommand(),

      // Monitor
      'monitor': MonitorCommand(),

      // History and Alias
      'history': HistoryCommand(),
      'alias': AliasCommand(),

      // Storage and fixes
      'storage': StorageCommand(),
      'fix': FixCommand(),
      'tree': TreeCommand(),
      'setup-storage': SetupStorageCommand(),
    };

    _commands['help'] = HelpCommand(_commands);
  }

  Future<CommandResult> handleCommand(
    String input,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    final parts = input.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) {
      return CommandResult.success('');
    }

    var commandName = parts[0].toLowerCase();

    // Check for alias
    final alias = AliasCommand.getAlias(commandName);
    if (alias != null) {
      final aliasedInput =
          alias + (parts.length > 1 ? ' ${parts.sublist(1).join(' ')}' : '');
      return await handleCommand(aliasedInput, shellService, appService);
    }

    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    // Record command for macro
    if (_macroService.isRecording) {
      _macroService.recordCommand(input);
    }

    // Handle macro execution
    if (commandName == 'macro' &&
        args.isNotEmpty &&
        args[0] == 'run' &&
        args.length > 1) {
      final macroName = args[1];
      final macro = _macroService.getMacro(macroName);

      if (macro != null) {
        for (var cmd in macro.commands) {
          await Future.delayed(const Duration(milliseconds: 100));
          await handleCommand(cmd, shellService, appService);
        }
        return CommandResult.success('Macro executed');
      }
    }

    // Check for built-in commands
    if (_commands.containsKey(commandName)) {
      final command = _commands[commandName]!;
      return await command.execute(args, shellService, appService);
    }

    // Check if command exists in our bin directory
    final binPath = '${_packageService.binDir}/$commandName';
    final binFile = File(binPath);
    if (await binFile.exists()) {
      try {
        final result = await Process.run(binPath, args);
        if (result.stdout.toString().isNotEmpty) {
          shellService.addOutput(result.stdout.toString());
        }
        if (result.stderr.toString().isNotEmpty) {
          shellService.addOutput(
            result.stderr.toString(),
            type: LineType.error,
          );
        }
        return CommandResult.success('Command executed from bin');
      } catch (e) {
        shellService.addOutput(
          'Error executing $commandName: $e',
          type: LineType.error,
        );
      }
    }

    // If not a built-in command, try to execute as shell command
    return await shellService.executeCommand(input);
  }

  SSHService get sshService => _sshService;
  BackupService get backupService => _backupService;
  MacroService get macroService => _macroService;
  PackageManagerService get packageService => _packageService;

  Future<void> openNanoEditor(BuildContext context, String filename) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NanoEditorScreen(filePath: filename)),
    );
  }
}
