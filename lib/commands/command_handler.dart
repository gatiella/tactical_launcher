import 'base_command.dart';
import 'app_commands.dart';
import 'system_commands.dart';
import 'package_commands.dart';
import 'advanced_commands.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../services/package_manager_service.dart';
import '../services/ssh_service.dart';
import '../services/backup_service.dart';
import '../services/macro_service.dart';
import '../models/command_result.dart';


class CommandHandler {
  late final Map<String, BaseCommand> _commands;
  final PackageManagerService _packageService = PackageManagerService();
  final SSHService _sshService = SSHService();
  final BackupService _backupService = BackupService();
  final MacroService _macroService = MacroService();

CommandHandler() {
  _commands = {
// Existing commands...
    'help': HelpCommand({}),
    'clear': ClearCommand(),
    'status': StatusCommand(),
    'pwd': PwdCommand(),
    'ls': LsCommand(),
    'cd': CdCommand(),
    'cat': CatCommand(),
    'apps': AppsCommand(),
    'search': SearchCommand(),
    'open': OpenCommand(),
    'pkg': PkgCommand(_packageService),
    'go': GoCommand(_packageService),
    
   // NEW Advanced commands
    'mkdir': MkdirCommand(),
    'rm': RmCommand(),
    'cp': CpCommand(),
    'mv': MvCommand(),
    'touch': TouchCommand(),
    'echo': EchoCommand(),
    'grep': GrepCommand(),
    'ping': PingCommand(),
    'wget': WgetCommand(),
    'ps': PsCommand(),
    'nano': NanoCommand(),
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

    final commandName = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    // Record command if macro recording is active
    if (_macroService.isRecording) {
      _macroService.recordCommand(input);
    }

    // Handle macro execution (special case - needs to execute multiple commands)
    if (commandName == 'macro' && args.isNotEmpty && args[0] == 'run' && args.length > 1) {
      final macroName = args[1];
      final macro = _macroService.getMacro(macroName);
      
      if (macro != null) {
        // Execute macro commands in sequence
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

    // If not a built-in command, try to execute as shell command
    return await shellService.executeCommand(input);
  }

  SSHService get sshService => _sshService;
  BackupService get backupService => _backupService;
  MacroService get macroService => _macroService;
}