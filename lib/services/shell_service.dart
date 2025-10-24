import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class ShellService extends ChangeNotifier {
  final List<TerminalLine> _history = [];
  String _currentDirectory = '';
  final Map<String, String> _environment = {};

  List<TerminalLine> get history => List.unmodifiable(_history);
  String get currentDirectory => _currentDirectory;

  ShellService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _currentDirectory = Directory.current.path;
    _addLine(TerminalLine.info('Tactical OS v2.1 initialized'));
    _addLine(TerminalLine.info('Type "help" for available commands'));
    _addLine(TerminalLine.info('═' * 50));
    notifyListeners();
  }

  void _addLine(TerminalLine line) {
    _history.add(line);
    notifyListeners();
  }

  Future<CommandResult> executeCommand(String command) async {
    _addLine(TerminalLine.input('root@tactical:~\$ $command'));

    if (command.trim().isEmpty) {
      return CommandResult.success('');
    }

    try {
      // Split command and arguments
      final parts = command.trim().split(' ');
      final cmd = parts[0];
      final args = parts.length > 1 ? parts.sublist(1) : <String>[];

      // Execute command
      final result = await Process.run(
        cmd,
        args,
        workingDirectory: _currentDirectory,
        environment: _environment,
        runInShell: true,
      );

      final output = result.stdout.toString();
      final error = result.stderr.toString();

      if (result.exitCode == 0) {
        if (output.isNotEmpty) {
          for (var line in output.split('\n')) {
            if (line.isNotEmpty) {
              _addLine(TerminalLine.output(line));
            }
          }
        }
        return CommandResult.success(output);
      } else {
        if (error.isNotEmpty) {
          _addLine(TerminalLine.error(error));
        }
        return CommandResult.error(error, exitCode: result.exitCode);
      }
    } catch (e) {
      final errorMsg = 'Error: $e';
      _addLine(TerminalLine.error(errorMsg));
      return CommandResult.error(errorMsg);
    }
  }

  Future<CommandResult> changeDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        _currentDirectory = dir.path;
        _addLine(TerminalLine.success('Changed directory to: $path'));
        return CommandResult.success(_currentDirectory);
      } else {
        final error = 'Directory not found: $path';
        _addLine(TerminalLine.error(error));
        return CommandResult.error(error);
      }
    } catch (e) {
      final error = 'Error changing directory: $e';
      _addLine(TerminalLine.error(error));
      return CommandResult.error(error);
    }
  }

  void clear() {
    _history.clear();
    _addLine(TerminalLine.info('Terminal cleared'));
    notifyListeners();
  }

  void addOutput(String text, {LineType type = LineType.output}) {
    _addLine(TerminalLine(text: text, type: type));
  }
}