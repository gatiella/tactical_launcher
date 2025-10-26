import 'dart:io';
import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class GitCommand extends BaseCommand {
  @override
  String get name => 'git';

  @override
  String get description => 'Git version control commands';

  @override
  String get usage => 'git <init|status|add|commit|push|pull|clone|log|branch>';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No git command specified');
    }

    final gitCommand = args[0];

    switch (gitCommand) {
      case 'init':
        return await _gitInit(shellService);

      case 'status':
        return await _gitStatus(shellService);

      case 'add':
        if (args.length < 2) {
          shellService.addOutput(
            'Usage: git add <file|.>',
            type: LineType.error,
          );
          return CommandResult.error('No file specified');
        }
        return await _gitAdd(args[1], shellService);

      case 'commit':
        if (args.length < 2) {
          shellService.addOutput(
            'Usage: git commit -m "message"',
            type: LineType.error,
          );
          return CommandResult.error('No message specified');
        }
        final message = args
            .sublist(1)
            .join(' ')
            .replaceAll('-m', '')
            .trim()
            .replaceAll('"', '');
        return await _gitCommit(message, shellService);

      case 'push':
        return await _gitPush(
          args.length > 1 ? args.sublist(1) : [],
          shellService,
        );

      case 'pull':
        return await _gitPull(
          args.length > 1 ? args.sublist(1) : [],
          shellService,
        );

      case 'clone':
        if (args.length < 2) {
          shellService.addOutput(
            'Usage: git clone <url>',
            type: LineType.error,
          );
          return CommandResult.error('No URL specified');
        }
        return await _gitClone(args[1], shellService);

      case 'log':
        return await _gitLog(shellService);

      case 'branch':
        return await _gitBranch(
          args.length > 1 ? args.sublist(1) : [],
          shellService,
        );

      case 'checkout':
        if (args.length < 2) {
          shellService.addOutput(
            'Usage: git checkout <branch>',
            type: LineType.error,
          );
          return CommandResult.error('No branch specified');
        }
        return await _gitCheckout(args[1], shellService);

      case 'diff':
        return await _gitDiff(shellService);

      case 'remote':
        return await _gitRemote(
          args.length > 1 ? args.sublist(1) : [],
          shellService,
        );

      default:
        shellService.addOutput(
          'Unknown git command: $gitCommand',
          type: LineType.error,
        );
        printHelp(shellService);
        return CommandResult.error('Unknown command');
    }
  }

  Future<CommandResult> _gitInit(ShellService shellService) async {
    try {
      shellService.addOutput('Initializing Git repository...');

      final result = await Process.run('git', ['init']);

      if (result.exitCode == 0) {
        shellService.addOutput(
          '✓ Git repository initialized',
          type: LineType.success,
        );
        shellService.addOutput(result.stdout.toString().trim());
        return CommandResult.success('Repository initialized');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Init failed');
      }
    } catch (e) {
      shellService.addOutput(
        'Git not found. Install git first.',
        type: LineType.error,
      );
      return CommandResult.error('Git not installed');
    }
  }

  Future<CommandResult> _gitStatus(ShellService shellService) async {
    try {
      final result = await Process.run('git', ['status']);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        _parseAndColorizeStatus(output, shellService);
        return CommandResult.success('Status displayed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Status failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  void _parseAndColorizeStatus(String output, ShellService shellService) {
    final lines = output.split('\n');

    for (var line in lines) {
      if (line.contains('On branch')) {
        shellService.addOutput(line, type: LineType.success);
      } else if (line.contains('modified:') || line.contains('deleted:')) {
        shellService.addOutput(line, type: LineType.warning);
      } else if (line.contains('new file:') ||
          line.contains('Untracked files:')) {
        shellService.addOutput(line, type: LineType.info);
      } else if (line.trim().isNotEmpty) {
        shellService.addOutput(line);
      }
    }
  }

  Future<CommandResult> _gitAdd(String file, ShellService shellService) async {
    try {
      shellService.addOutput('Adding files to staging area...');

      final result = await Process.run('git', ['add', file]);

      if (result.exitCode == 0) {
        shellService.addOutput(
          '✓ Files staged successfully',
          type: LineType.success,
        );
        return CommandResult.success('Files added');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Add failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _gitCommit(
    String message,
    ShellService shellService,
  ) async {
    try {
      shellService.addOutput('Creating commit...');

      final result = await Process.run('git', ['commit', '-m', message]);

      if (result.exitCode == 0) {
        shellService.addOutput(
          '✓ Commit created successfully',
          type: LineType.success,
        );
        shellService.addOutput(result.stdout.toString().trim());
        return CommandResult.success('Commit created');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Commit failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _gitPush(
    List<String> args,
    ShellService shellService,
  ) async {
    try {
      shellService.addOutput('Pushing to remote...');

      final result = await Process.run('git', ['push', ...args]);

      if (result.exitCode == 0) {
        shellService.addOutput('✓ Push successful', type: LineType.success);
        shellService.addOutput(result.stdout.toString().trim());
        return CommandResult.success('Push completed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Push failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _gitPull(
    List<String> args,
    ShellService shellService,
  ) async {
    try {
      shellService.addOutput('Pulling from remote...');

      final result = await Process.run('git', ['pull', ...args]);

      if (result.exitCode == 0) {
        shellService.addOutput('✓ Pull successful', type: LineType.success);
        shellService.addOutput(result.stdout.toString().trim());
        return CommandResult.success('Pull completed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Pull failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _gitClone(String url, ShellService shellService) async {
    try {
      shellService.addOutput('Cloning repository...');
      shellService.addOutput('URL: $url');

      final result = await Process.run('git', ['clone', url]);

      if (result.exitCode == 0) {
        shellService.addOutput(
          '✓ Repository cloned successfully',
          type: LineType.success,
        );
        shellService.addOutput(result.stdout.toString().trim());
        return CommandResult.success('Clone completed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Clone failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _gitLog(ShellService shellService) async {
    try {
      final result = await Process.run('git', ['log', '--oneline', '-10']);

      if (result.exitCode == 0) {
        shellService.addOutput('═' * 50);
        shellService.addOutput('RECENT COMMITS', type: LineType.info);
        shellService.addOutput('═' * 50);

        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            shellService.addOutput(line, type: LineType.success);
          }
        }

        shellService.addOutput('═' * 50);
        return CommandResult.success('Log displayed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Log failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _gitBranch(
    List<String> args,
    ShellService shellService,
  ) async {
    try {
      final result = await Process.run('git', ['branch', ...args]);

      if (result.exitCode == 0) {
        shellService.addOutput('═' * 50);
        shellService.addOutput('BRANCHES', type: LineType.info);
        shellService.addOutput('═' * 50);

        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            if (line.contains('*')) {
              shellService.addOutput(line, type: LineType.success);
            } else {
              shellService.addOutput(line);
            }
          }
        }

        shellService.addOutput('═' * 50);
        return CommandResult.success('Branches listed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Branch failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _gitCheckout(
    String branch,
    ShellService shellService,
  ) async {
    try {
      shellService.addOutput('Switching to branch: $branch');

      final result = await Process.run('git', ['checkout', branch]);

      if (result.exitCode == 0) {
        shellService.addOutput('✓ Switched to $branch', type: LineType.success);
        return CommandResult.success('Checkout completed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Checkout failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _gitDiff(ShellService shellService) async {
    try {
      final result = await Process.run('git', ['diff', '--stat']);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        if (output.trim().isEmpty) {
          shellService.addOutput('No changes', type: LineType.info);
        } else {
          shellService.addOutput('═' * 50);
          shellService.addOutput('CHANGES', type: LineType.info);
          shellService.addOutput('═' * 50);
          shellService.addOutput(output);
          shellService.addOutput('═' * 50);
        }
        return CommandResult.success('Diff displayed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Diff failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> _gitRemote(
    List<String> args,
    ShellService shellService,
  ) async {
    try {
      final result = await Process.run('git', ['remote', '-v']);

      if (result.exitCode == 0) {
        shellService.addOutput('═' * 50);
        shellService.addOutput('REMOTES', type: LineType.info);
        shellService.addOutput('═' * 50);

        final output = result.stdout.toString();
        if (output.trim().isEmpty) {
          shellService.addOutput('No remotes configured', type: LineType.info);
        } else {
          shellService.addOutput(output);
        }

        shellService.addOutput('═' * 50);
        return CommandResult.success('Remotes listed');
      } else {
        shellService.addOutput(result.stderr.toString(), type: LineType.error);
        return CommandResult.error('Remote failed');
      }
    } catch (e) {
      shellService.addOutput('Error: $e', type: LineType.error);
      return CommandResult.error(e.toString());
    }
  }
}
