class CommandResult {
  final bool success;
  final String output;
  final String? error;
  final int exitCode;

  CommandResult({
    required this.success,
    required this.output,
    this.error,
    this.exitCode = 0,
  });

  factory CommandResult.success(String output) {
    return CommandResult(
      success: true,
      output: output,
      exitCode: 0,
    );
  }

  factory CommandResult.error(String error, {int exitCode = 1}) {
    return CommandResult(
      success: false,
      output: '',
      error: error,
      exitCode: exitCode,
    );
  }
}