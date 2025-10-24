import 'package:flutter/material.dart';
import '../themes/terminal_theme.dart';

class QuickActionsWidget extends StatelessWidget {
  final Function(String) onCommand;

  const QuickActionsWidget({
    super.key,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '▸ QUICK ACTIONS',
            style: TerminalTheme.promptText.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip('Apps', 'apps', Icons.apps),
              _buildActionChip('Status', 'status', Icons.info_outline),
              _buildActionChip('Files', 'ls', Icons.folder_open),
              _buildActionChip('Clear', 'clear', Icons.clear_all),
              _buildActionChip('Help', 'help', Icons.help_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, String command, IconData icon) {
    return InkWell(
      onTap: () => onCommand(command),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: TerminalTheme.matrixGreen, width: 1),
          borderRadius: BorderRadius.circular(6),
          color: TerminalTheme.matrixGreen.withOpacity(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: TerminalTheme.matrixGreen),
            const SizedBox(width: 6),
            Text(label, style: TerminalTheme.terminalText.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}