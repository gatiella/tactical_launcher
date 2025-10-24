import 'dart:io';
import 'package:http/http.dart' as http;
import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class MkdirCommand extends BaseCommand {
  @override
  String get name => 'mkdir';

  @override
  String get description => 'Create a new directory';

  @override
  String get usage => 'mkdir <directory_name>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No directory name provided');
    }

    try {
      final dirName = args[0];
      final dir = Directory('${shellService.currentDirectory}/$dirName');
      
      if (await dir.exists()) {
        shellService.addOutput('Directory already exists: $dirName', type: LineType.warning);
        return CommandResult.error('Directory exists');
      }

      await dir.create(recursive: true);
      shellService.addOutput('✓ Directory created: $dirName', type: LineType.success);
      return CommandResult.success('Directory created');
    } catch (e) {
      shellService.addOutput('Error creating directory: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class RmCommand extends BaseCommand {
  @override
  String get name => 'rm';

  @override
  String get description => 'Remove files or directories';

  @override
  String get usage => 'rm <file|directory> [-r for recursive]';

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

    try {
      final recursive = args.contains('-r');
      final target = args.firstWhere((arg) => arg != '-r');
      final path = target.startsWith('/') ? target : '${shellService.currentDirectory}/$target';

      final file = File(path);
      final dir = Directory(path);

      if (await file.exists()) {
        await file.delete();
        shellService.addOutput('✓ File deleted: $target', type: LineType.success);
        return CommandResult.success('File deleted');
      } else if (await dir.exists()) {
        if (recursive) {
          await dir.delete(recursive: true);
          shellService.addOutput('✓ Directory deleted: $target', type: LineType.success);
          return CommandResult.success('Directory deleted');
        } else {
          shellService.addOutput('Use -r flag to delete directories', type: LineType.error);
          return CommandResult.error('Directory requires -r flag');
        }
      } else {
        shellService.addOutput('File or directory not found: $target', type: LineType.error);
        return CommandResult.error('Not found');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class CpCommand extends BaseCommand {
  @override
  String get name => 'cp';

  @override
  String get description => 'Copy files or directories';

  @override
  String get usage => 'cp <source> <destination>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.length < 2) {
      printHelp(shellService);
      return CommandResult.error('Source and destination required');
    }

    try {
      final source = args[0];
      final dest = args[1];
      final sourceFile = File(source);
      
      if (!await sourceFile.exists()) {
        shellService.addOutput('Source file not found: $source', type: LineType.error);
        return CommandResult.error('Source not found');
      }

      await sourceFile.copy(dest);
      shellService.addOutput('✓ File copied: $source → $dest', type: LineType.success);
      return CommandResult.success('File copied');
    } catch (e) {
      shellService.addOutput('Error copying file: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class MvCommand extends BaseCommand {
  @override
  String get name => 'mv';

  @override
  String get description => 'Move or rename files';

  @override
  String get usage => 'mv <source> <destination>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.length < 2) {
      printHelp(shellService);
      return CommandResult.error('Source and destination required');
    }

    try {
      final source = args[0];
      final dest = args[1];
      final sourceFile = File(source);
      
      if (!await sourceFile.exists()) {
        shellService.addOutput('Source file not found: $source', type: LineType.error);
        return CommandResult.error('Source not found');
      }

      await sourceFile.rename(dest);
      shellService.addOutput('✓ File moved: $source → $dest', type: LineType.success);
      return CommandResult.success('File moved');
    } catch (e) {
      shellService.addOutput('Error moving file: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class TouchCommand extends BaseCommand {
  @override
  String get name => 'touch';

  @override
  String get description => 'Create an empty file';

  @override
  String get usage => 'touch <filename>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No filename provided');
    }

    try {
      final filename = args[0];
      final file = File('${shellService.currentDirectory}/$filename');
      
      await file.create();
      shellService.addOutput('✓ File created: $filename', type: LineType.success);
      return CommandResult.success('File created');
    } catch (e) {
      shellService.addOutput('Error creating file: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class EchoCommand extends BaseCommand {
  @override
  String get name => 'echo';

  @override
  String get description => 'Display a line of text';

  @override
  String get usage => 'echo <text> [> file]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      return CommandResult.success('');
    }

    try {
      final redirectIndex = args.indexOf('>');
      
      if (redirectIndex != -1 && redirectIndex < args.length - 1) {
        // Redirect to file
        final text = args.sublist(0, redirectIndex).join(' ');
        final filename = args[redirectIndex + 1];
        final file = File('${shellService.currentDirectory}/$filename');
        
        await file.writeAsString('$text\n');
        shellService.addOutput('✓ Written to: $filename', type: LineType.success);
        return CommandResult.success('Written to file');
      } else {
        // Just output text
        final text = args.join(' ');
        shellService.addOutput(text);
        return CommandResult.success(text);
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class GrepCommand extends BaseCommand {
  @override
  String get name => 'grep';

  @override
  String get description => 'Search for patterns in files';

  @override
  String get usage => 'grep <pattern> <file>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.length < 2) {
      printHelp(shellService);
      return CommandResult.error('Pattern and file required');
    }

    try {
      final pattern = args[0];
      final filename = args[1];
      final file = File(filename);
      
      if (!await file.exists()) {
        shellService.addOutput('File not found: $filename', type: LineType.error);
        return CommandResult.error('File not found');
      }

      final lines = await file.readAsLines();
      final matches = lines.where((line) => line.contains(pattern)).toList();
      
      if (matches.isEmpty) {
        shellService.addOutput('No matches found', type: LineType.warning);
        return CommandResult.success('No matches');
      }

      for (var match in matches) {
        shellService.addOutput(match);
      }
      
      shellService.addOutput('', type: LineType.info);
      shellService.addOutput('Found ${matches.length} matches', type: LineType.success);
      return CommandResult.success('Found ${matches.length} matches');
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class PingCommand extends BaseCommand {
  @override
  String get name => 'ping';

  @override
  String get description => 'Check network connectivity';

  @override
  String get usage => 'ping <host>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No host specified');
    }

    try {
      final host = args[0];
      shellService.addOutput('Pinging $host...');
      
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse('https://$host')).timeout(
        const Duration(seconds: 5),
      );
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        shellService.addOutput('✓ $host is reachable (${stopwatch.elapsedMilliseconds}ms)', type: LineType.success);
        return CommandResult.success('Host reachable');
      } else {
        shellService.addOutput('✗ $host returned status ${response.statusCode}', type: LineType.warning);
        return CommandResult.error('Unexpected status');
      }
    } catch (e) {
      shellService.addOutput('✗ Unable to reach host: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class WgetCommand extends BaseCommand {
  @override
  String get name => 'wget';

  @override
  String get description => 'Download files from the internet';

  @override
  String get usage => 'wget <url> [output_filename]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No URL specified');
    }

    try {
      final url = args[0];
      final filename = args.length > 1 ? args[1] : url.split('/').last;
      
      shellService.addOutput('Downloading from $url...');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final file = File('${shellService.currentDirectory}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        
        shellService.addOutput('✓ Downloaded: $filename (${response.bodyBytes.length} bytes)', type: LineType.success);
        return CommandResult.success('Download complete');
      } else {
        shellService.addOutput('✗ Download failed: HTTP ${response.statusCode}', type: LineType.error);
        return CommandResult.error('Download failed');
      }
    } catch (e) {
      shellService.addOutput('Error downloading: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}

class PsCommand extends BaseCommand {
  @override
  String get name => 'ps';

  @override
  String get description => 'List running processes';

  @override
  String get usage => 'ps';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    try {
      shellService.addOutput('Running processes:', type: LineType.info);
      shellService.addOutput('═' * 50);
      
      final result = await Process.run('ps', []);
      
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            shellService.addOutput(line);
          }
        }
        return CommandResult.success('Processes listed');
      } else {
        shellService.addOutput('Unable to list processes', type: LineType.warning);
        shellService.addOutput('Try: apps (to see installed apps)', type: LineType.info);
        return CommandResult.error('Command not available');
      }
    } catch (e) {
      shellService.addOutput('Process listing not available on this device', type: LineType.warning);
      return CommandResult.error(e.toString());
    }
  }
}

class NanoCommand extends BaseCommand {
  @override
  String get name => 'nano';

  @override
  String get description => 'Simple text editor (opens settings)';

  @override
  String get usage => 'nano <filename>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      shellService.addOutput('Text editor feature coming soon!', type: LineType.info);
      shellService.addOutput('For now, use: echo "text" > file.txt', type: LineType.info);
      return CommandResult.success('Editor placeholder');
    }

    final filename = args[0];
    shellService.addOutput('Opening editor for: $filename', type: LineType.info);
    shellService.addOutput('Note: Full editor not yet implemented', type: LineType.warning);
    shellService.addOutput('Use "cat $filename" to view file', type: LineType.info);
    
    return CommandResult.success('Editor info shown');
  }
}