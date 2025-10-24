import 'package:flutter/material.dart';
import '../themes/terminal_theme.dart';

class CommandSuggestionsWidget extends StatelessWidget {
  final String input;
  final List<String> availableCommands;
  final Function(String) onCommandSelected;

  const CommandSuggestionsWidget({
    super.key,
    required this.input,
    required this.availableCommands,
    required this.onCommandSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (input.isEmpty) return const SizedBox.shrink();

    final suggestions = availableCommands
        .where((cmd) => cmd.startsWith(input.toLowerCase()))
        .take(5)
        .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: TerminalTheme.matrixGreen, width: 1),
        borderRadius: BorderRadius.circular(4),
        color: TerminalTheme.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Suggestions:',
            style: TerminalTheme.terminalText.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 4),
          ...suggestions.map((cmd) => InkWell(
            onTap: () => onCommandSelected(cmd),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                cmd,
                style: TerminalTheme.promptText.copyWith(fontSize: 12),
              ),
            ),
          )),
        ],
      ),
    );
  }
}