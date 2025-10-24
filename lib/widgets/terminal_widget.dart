import 'package:flutter/material.dart';
import '../models/terminal_line.dart';
import '../themes/terminal_theme.dart';

class TerminalWidget extends StatelessWidget {
  final List<TerminalLine> history;
  final ScrollController scrollController;

  const TerminalWidget({
    super.key,
    required this.history,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final line = history[index];
        return _buildTerminalLine(line);
      },
    );
  }

  Widget _buildTerminalLine(TerminalLine line) {
    TextStyle style;
    String prefix = '';

    switch (line.type) {
      case LineType.input:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line.text, style: TerminalTheme.promptText),
        );
      case LineType.error:
        style = TerminalTheme.errorText;
        prefix = '✗ ';
        break;
      case LineType.warning:
        style = TerminalTheme.warningText;
        prefix = '⚠ ';
        break;
      case LineType.success:
        style = TerminalTheme.terminalText;
        prefix = '✓ ';
        break;
      case LineType.info:
        style = TerminalTheme.terminalText.copyWith(
          color: TerminalTheme.cyberCyan,
        );
        prefix = '▸ ';
        break;
      case LineType.output:
      style = TerminalTheme.terminalText;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$prefix${line.text}',
        style: style,
      ),
    );
  }
}