import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class ShellService extends ChangeNotifier {
  final List<TerminalLine> _history = [];
  String _currentDirectory = '';
  String _homeDirectory = '';
  bool _storageSetup = false;
  final Map<String, String> _environment = {};

  List<TerminalLine> get history => List.unmodifiable(_history);
  String get currentDirectory => _currentDirectory;
  String get homeDirectory => _homeDirectory;
  bool get isStorageSetup => _storageSetup;

  // Get display path (replace storage path with ~)
  String get displayPath {
    if (_currentDirectory == _homeDirectory) {
      return '~';
    } else if (_currentDirectory.startsWith(_homeDirectory)) {
      return '~${_currentDirectory.substring(_homeDirectory.length)}';
    } else if (_currentDirectory.startsWith('/storage/emulated/0')) {
      return _currentDirectory.replaceFirst('/storage/emulated/0', '~/storage');
    }
    return _currentDirectory;
  }

  ShellService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Check if we have storage permission
      final hasPermission =
          await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted;

      if (hasPermission) {
        // Try to use external storage
        final externalDir = Directory('/storage/emulated/0');
        if (await externalDir.exists()) {
          try {
            await externalDir.list().take(1).toList();
            _homeDirectory = externalDir.path;
            _currentDirectory = _homeDirectory;
            _storageSetup = true;
          } catch (e) {
            await _useAppDirectory();
          }
        } else {
          await _useAppDirectory();
        }
      } else {
        await _useAppDirectory();
      }

      final dir = Directory(_currentDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      await _useAppDirectory();
    }

    _addLine(TerminalLine.info('Tactical OS v2.1 initialized'));
    _addLine(TerminalLine.info('Type "help" for available commands'));
    if (!_storageSetup) {
      _addLine(
        TerminalLine.warning('Run "setup-storage" to access device storage'),
      );
    }
    _addLine(TerminalLine.info('═' * 50));
    notifyListeners();
  }

  Future<void> _useAppDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _homeDirectory = appDir.path;
    _currentDirectory = _homeDirectory;
    _storageSetup = false;
  }

  Future<void> setupStorage() async {
    try {
      // Request permissions
      final storageStatus = await Permission.storage.request();
      final manageStatus = await Permission.manageExternalStorage.request();

      if (!storageStatus.isGranted && !manageStatus.isGranted) {
        throw Exception('Storage permissions not granted');
      }

      // Switch to external storage
      final externalDir = Directory('/storage/emulated/0');
      if (await externalDir.exists()) {
        try {
          await externalDir.list().take(1).toList();
          _homeDirectory = externalDir.path;
          _currentDirectory = _homeDirectory;
          _storageSetup = true;
          notifyListeners();
        } catch (e) {
          throw Exception('Cannot access storage');
        }
      } else {
        throw Exception('External storage not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  void _addLine(TerminalLine line) {
    _history.add(line);
    notifyListeners();
  }

  Future<CommandResult> executeCommand(String command) async {
    final prompt = '${displayPath} \$ $command';
    _addLine(TerminalLine.input(prompt));

    if (command.trim().isEmpty) {
      return CommandResult.success('');
    }

    final parts = command.trim().split(' ');
    final cmd = parts[0];
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    try {
      final result =
          await Process.run(
            cmd,
            args,
            workingDirectory: _currentDirectory,
            environment: _environment,
            runInShell: true,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Command timed out after 30 seconds');
            },
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
    } on ProcessException {
      final errorMsg = '$cmd: command not found';
      _addLine(TerminalLine.error(errorMsg));
      return CommandResult.error(errorMsg);
    } on TimeoutException catch (e) {
      final errorMsg = 'Command timed out: $e';
      _addLine(TerminalLine.error(errorMsg));
      return CommandResult.error(errorMsg);
    } catch (e) {
      final errorMsg = 'Error: $e';
      _addLine(TerminalLine.error(errorMsg));
      return CommandResult.error(errorMsg);
    }
  }

  Future<CommandResult> changeDirectory(String path) async {
    try {
      String expandedPath = path;

      if (path == '~' || path == '') {
        expandedPath = _homeDirectory;
      } else if (path.startsWith('~/storage')) {
        // Handle ~/storage paths
        expandedPath = path.replaceFirst('~/storage', '/storage/emulated/0');
      } else if (path.startsWith('~/')) {
        expandedPath = path.replaceFirst('~/', '$_homeDirectory/');
      } else if (path == '..') {
        final parentPath = Directory(_currentDirectory).parent.path;
        expandedPath = parentPath;
      } else if (path.startsWith('../')) {
        expandedPath = _resolvePath(path);
      } else if (path.startsWith('./')) {
        expandedPath = '$_currentDirectory/${path.substring(2)}';
      } else if (!path.startsWith('/')) {
        expandedPath = '$_currentDirectory/$path';
      }

      expandedPath = _normalizePath(expandedPath);

      final dir = Directory(expandedPath);

      if (!await dir.exists()) {
        final error = 'cd: no such file or directory: $path';
        _addLine(TerminalLine.error(error));
        return CommandResult.error(error);
      }

      try {
        await dir.list().take(1).toList();
      } catch (e) {
        final error = 'cd: permission denied: $path';
        _addLine(TerminalLine.error(error));
        return CommandResult.error(error);
      }

      _currentDirectory = dir.path;
      notifyListeners();
      return CommandResult.success(_currentDirectory);
    } catch (e) {
      final error = 'cd: $e';
      _addLine(TerminalLine.error(error));
      return CommandResult.error(error);
    }
  }

  String _resolvePath(String relativePath) {
    final parts = relativePath.split('/');
    final currentParts = _currentDirectory.split('/');

    for (var part in parts) {
      if (part == '..') {
        if (currentParts.isNotEmpty) {
          currentParts.removeLast();
        }
      } else if (part != '.' && part.isNotEmpty) {
        currentParts.add(part);
      }
    }

    return currentParts.join('/');
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

  void clear() {
    _history.clear();
    notifyListeners();
  }

  void addOutput(String text, {LineType type = LineType.output}) {
    _addLine(TerminalLine(text: text, type: type));
  }

  Future<bool> commandExists(String command) async {
    try {
      final result = await Process.run('which', [command]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
