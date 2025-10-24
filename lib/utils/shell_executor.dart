import 'dart:io';
import '../models/command_result.dart';

class ShellExecutor {
  static Future<CommandResult> execute(
    String command, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    try {
      final parts = command.split(' ');
      final cmd = parts[0];
      final args = parts.length > 1 ? parts.sublist(1) : <String>[];

      final result = await Process.run(
        cmd,
        args,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: true,
      );

      return CommandResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.stderr.toString(),
        exitCode: result.exitCode,
      );
    } catch (e) {
      return CommandResult.error(e.toString());
    }
  }

  static Future<Stream<String>> executeStreaming(
    String command, {
    String? workingDirectory,
  }) async {
    final parts = command.split(' ');
    final cmd = parts[0];
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    final process = await Process.start(
      cmd,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    return process.stdout.map((data) => String.fromCharCodes(data));
  }
}