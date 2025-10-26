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
        shellService.addOutput(
          '${entry.key.padRight(15)} - ${entry.value.description}',
        );
      }

      shellService.addOutput('═' * 50);
      shellService.addOutput(
        'Type "help <command>" for detailed usage',
        type: LineType.info,
      );
    } else {
      final cmdName = args[0];
      final cmd = commands[cmdName];

      if (cmd == null) {
        shellService.addOutput(
          'Unknown command: $cmdName',
          type: LineType.error,
        );
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

    try {
      await getApplicationDocumentsDirectory();

      shellService.addOutput('SYSTEM STATUS', type: LineType.info);
      shellService.addOutput('═' * 50);
      shellService.addOutput('Platform: ${Platform.operatingSystem}');
      shellService.addOutput('Version: ${Platform.operatingSystemVersion}');
      shellService.addOutput('Current Dir: ${shellService.currentDirectory}');
      shellService.addOutput('Home Dir: ${shellService.homeDirectory}');
      shellService.addOutput('');
      shellService.addOutput(
        'Installed Apps: ${appService.installedApps.length}',
      );
      shellService.addOutput('═' * 50);
    } catch (e) {
      shellService.addOutput(
        'Error getting system info: $e',
        type: LineType.error,
      );
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
  String get usage => 'ls [path] [-a] [-l]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    try {
      String path = shellService.currentDirectory;
      bool showHidden = false;

      // Parse arguments
      for (var arg in args) {
        if (arg == '-a' || arg == '--all') {
          showHidden = true;
        } else if (arg == '-l' || arg == '--long') {
        } else if (!arg.startsWith('-')) {
          path = arg;
          // Handle relative paths
          if (!path.startsWith('/') && !path.startsWith('~')) {
            path = '${shellService.currentDirectory}/$path';
          } else if (path.startsWith('~')) {
            path = path.replaceFirst('~', shellService.homeDirectory);
          } else if (path == '..') {
            path = Directory(shellService.currentDirectory).parent.path;
          }
        }
      }

      // Normalize path
      if (path.contains('..') || path.contains('./')) {
        path = _normalizePath(path);
      }

      final dir = Directory(path);

      if (!await dir.exists()) {
        shellService.addOutput(
          'ls: $path: No such file or directory',
          type: LineType.error,
        );
        return CommandResult.error('Directory not found');
      }

      try {
        final entities = await dir.list().toList();

        // Filter hidden files unless -a is specified
        final filteredEntities = showHidden
            ? entities
            : entities.where((e) {
                final name = e.path.split('/').last;
                return !name.startsWith('.');
              }).toList();

        if (filteredEntities.isEmpty) {
          return CommandResult.success('Empty');
        }

        // Sort: directories first, then files (alphabetically)
        filteredEntities.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });

        // Simple column layout like Termux
        final List<String> names = [];
        for (var entity in filteredEntities) {
          final name = entity.path.split('/').last;
          names.add(name);
        }

        // Display in columns (4 columns like Termux)
        final columns = 4;
        final maxWidth = 20;

        for (int i = 0; i < names.length; i += columns) {
          final row = names.skip(i).take(columns).toList();
          final rowText = row.map((n) => n.padRight(maxWidth)).join('');
          shellService.addOutput(rowText);
        }

        return CommandResult.success('Listed ${filteredEntities.length} items');
      } catch (e) {
        shellService.addOutput(
          'ls: $path: Permission denied',
          type: LineType.error,
        );
        return CommandResult.error('Permission denied');
      }
    } catch (e) {
      shellService.addOutput('ls: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  String _normalizePath(String path) {
    final parts = path
        .split('/')
        .where((p) => p.isNotEmpty && p != '.')
        .toList();
    final normalized = <String>[];

    for (var part in parts) {
      if (part == '..') {
        if (normalized.isNotEmpty) {
          normalized.removeLast();
        }
      } else {
        normalized.add(part);
      }
    }

    return normalized.isEmpty ? '/' : '/${normalized.join('/')}';
  }
}

class CdCommand extends BaseCommand {
  @override
  String get name => 'cd';

  @override
  String get description => 'Change directory';

  @override
  String get usage => 'cd [path|~|..|../<path>]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      // cd with no args goes to home
      return await shellService.changeDirectory('~');
    }

    return await shellService.changeDirectory(args[0]);
  }

  @override
  void printHelp(ShellService shellService) {
    shellService.addOutput('═' * 50);
    shellService.addOutput('CD - Change Directory', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('Usage: cd [path]');
    shellService.addOutput('');
    shellService.addOutput('Examples:', type: LineType.success);
    shellService.addOutput('  cd              Go to home directory');
    shellService.addOutput('  cd ~            Go to home directory');
    shellService.addOutput('  cd /path/to/dir Go to absolute path');
    shellService.addOutput('  cd dirname      Go to subdirectory');
    shellService.addOutput('  cd ..           Go up one directory');
    shellService.addOutput('  cd ../..        Go up two directories');
    shellService.addOutput('  cd ./subdir     Go to subdirectory (explicit)');
    shellService.addOutput('  cd ~/Documents  Go to home/Documents');
    shellService.addOutput('═' * 50);
  }
}

class HistoryCommand extends BaseCommand {
  @override
  String get name => 'history';

  @override
  String get description => 'Show command history';

  @override
  String get usage => 'history [--clear]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isNotEmpty && args[0] == '--clear') {
      shellService.clear();
      return CommandResult.success('History cleared');
    }

    final history = shellService.history
        .where((line) => line.type == LineType.input)
        .toList();

    if (history.isEmpty) {
      shellService.addOutput('No command history', type: LineType.info);
      return CommandResult.success('Empty history');
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('COMMAND HISTORY', type: LineType.info);
    shellService.addOutput('═' * 50);

    for (var i = 0; i < history.length; i++) {
      shellService.addOutput('${i + 1}. ${history[i].text}');
    }

    shellService.addOutput('═' * 50);
    return CommandResult.success('Listed ${history.length} commands');
  }
}

class AliasCommand extends BaseCommand {
  static final Map<String, String> _aliases = {};

  @override
  String get name => 'alias';

  @override
  String get description => 'Create command aliases';

  @override
  String get usage => 'alias <name>=<command> or alias [--list]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty || args[0] == '--list') {
      return _listAliases(shellService);
    }

    final input = args.join(' ');
    if (!input.contains('=')) {
      shellService.addOutput('Usage: alias name=command', type: LineType.error);
      return CommandResult.error('Invalid format');
    }

    final parts = input.split('=');
    final name = parts[0].trim();
    final command = parts[1].trim();

    _aliases[name] = command;
    shellService.addOutput(
      '✓ Alias created: $name → $command',
      type: LineType.success,
    );

    return CommandResult.success('Alias created');
  }

  CommandResult _listAliases(ShellService shellService) {
    if (_aliases.isEmpty) {
      shellService.addOutput('No aliases defined', type: LineType.info);
      return CommandResult.success('No aliases');
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('DEFINED ALIASES', type: LineType.info);
    shellService.addOutput('═' * 50);

    for (var entry in _aliases.entries) {
      shellService.addOutput('${entry.key} → ${entry.value}');
    }

    shellService.addOutput('═' * 50);
    return CommandResult.success('Listed ${_aliases.length} aliases');
  }

  static String? getAlias(String name) => _aliases[name];
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
      String filePath = args[0];

      // Handle relative paths
      if (!filePath.startsWith('/') && !filePath.startsWith('~')) {
        filePath = '${shellService.currentDirectory}/$filePath';
      } else if (filePath.startsWith('~')) {
        filePath = filePath.replaceFirst('~', shellService.homeDirectory);
      }

      final file = File(filePath);

      if (!await file.exists()) {
        shellService.addOutput(
          'cat: $filePath: No such file or directory',
          type: LineType.error,
        );
        return CommandResult.error('File not found');
      }

      final contents = await file.readAsString();
      shellService.addOutput(contents);

      return CommandResult.success('File displayed');
    } catch (e) {
      shellService.addOutput('cat: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class TreeCommand extends BaseCommand {
  @override
  String get name => 'tree';

  @override
  String get description => 'Display directory tree structure';

  @override
  String get usage => 'tree [path] [--depth N]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    try {
      String path = shellService.currentDirectory;
      int maxDepth = 2;

      // Parse arguments
      for (int i = 0; i < args.length; i++) {
        if (args[i] == '--depth' && i + 1 < args.length) {
          maxDepth = int.tryParse(args[i + 1]) ?? 2;
        } else if (!args[i].startsWith('--') &&
            !RegExp(r'^\d+$').hasMatch(args[i])) {
          path = args[i];
          // Handle relative paths
          if (!path.startsWith('/') && !path.startsWith('~')) {
            path = '${shellService.currentDirectory}/$path';
          } else if (path.startsWith('~')) {
            path = path.replaceFirst('~', shellService.homeDirectory);
          }
        }
      }

      final dir = Directory(path);
      if (!await dir.exists()) {
        shellService.addOutput(
          'tree: $path: No such file or directory',
          type: LineType.error,
        );
        return CommandResult.error('Directory not found');
      }

      shellService.addOutput('📁 $path', type: LineType.success);
      int totalDirs = 0;
      int totalFiles = 0;

      await _printTree(dir, shellService, '', 0, maxDepth, (dirs, files) {
        totalDirs += dirs;
        totalFiles += files;
      });

      shellService.addOutput('');
      shellService.addOutput('$totalDirs directories, $totalFiles files');

      return CommandResult.success('Tree displayed');
    } catch (e) {
      shellService.addOutput('tree: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<void> _printTree(
    Directory dir,
    ShellService shellService,
    String prefix,
    int depth,
    int maxDepth,
    Function(int dirs, int files) counter,
  ) async {
    if (depth >= maxDepth) return;

    try {
      final entities = await dir.list().toList();
      final dirs = entities.whereType<Directory>().where((d) {
        final name = d.path.split('/').last;
        return !name.startsWith('.');
      }).toList();

      final files = entities.whereType<File>().where((f) {
        final name = f.path.split('/').last;
        return !name.startsWith('.');
      }).toList();

      counter(dirs.length, files.length);

      for (int i = 0; i < dirs.length; i++) {
        final isLast = i == dirs.length - 1 && files.isEmpty;
        final connector = isLast ? '└── ' : '├── ';
        final name = dirs[i].path.split('/').last;

        shellService.addOutput('$prefix$connector📁 $name/');

        final newPrefix = prefix + (isLast ? '    ' : '│   ');
        await _printTree(
          dirs[i],
          shellService,
          newPrefix,
          depth + 1,
          maxDepth,
          counter,
        );
      }

      for (int i = 0; i < files.length; i++) {
        final isLast = i == files.length - 1;
        final connector = isLast ? '└── ' : '├── ';
        final name = files[i].path.split('/').last;

        shellService.addOutput('$prefix$connector📄 $name');
      }
    } catch (e) {
      // Permission denied or other error
      shellService.addOutput(
        '$prefix[Permission denied]',
        type: LineType.warning,
      );
    }
  }

  @override
  void printHelp(ShellService shellService) {
    shellService.addOutput('═' * 50);
    shellService.addOutput(
      'TREE - Display Directory Tree',
      type: LineType.info,
    );
    shellService.addOutput('═' * 50);
    shellService.addOutput('Usage: tree [path] [--depth N]');
    shellService.addOutput('');
    shellService.addOutput('Options:', type: LineType.success);
    shellService.addOutput(
      '  --depth N   Maximum depth to display (default: 2)',
    );
    shellService.addOutput('');
    shellService.addOutput('Examples:', type: LineType.success);
    shellService.addOutput('  tree              Show current directory tree');
    shellService.addOutput('  tree /path        Show specific directory tree');
    shellService.addOutput('  tree --depth 3    Show tree with depth 3');
    shellService.addOutput('  tree ~ --depth 1  Show home directory (depth 1)');
    shellService.addOutput('═' * 50);
  }
}
