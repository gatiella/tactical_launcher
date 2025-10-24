enum LineType { input, output, error, warning, success, info }

class TerminalLine {
  final String text;
  final LineType type;
  final DateTime timestamp;

  TerminalLine({
    required this.text,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TerminalLine.input(String text) =>
      TerminalLine(text: text, type: LineType.input);

  factory TerminalLine.output(String text) =>
      TerminalLine(text: text, type: LineType.output);

  factory TerminalLine.error(String text) =>
      TerminalLine(text: text, type: LineType.error);

  factory TerminalLine.warning(String text) =>
      TerminalLine(text: text, type: LineType.warning);

  factory TerminalLine.success(String text) =>
      TerminalLine(text: text, type: LineType.success);

  factory TerminalLine.info(String text) =>
      TerminalLine(text: text, type: LineType.info);
}