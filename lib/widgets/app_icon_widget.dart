import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../themes/terminal_theme.dart';

class AppIconWidget extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;

  const AppIconWidget({
    super.key,
    required this.app,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: TerminalTheme.matrixGreen.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: TerminalTheme.matrixGreen.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TerminalTheme.matrixGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TerminalTheme.matrixGreen, width: 1),
              ),
              child: Center(
                child: Text(
                  app.name[0].toUpperCase(),
                  style: TextStyle(
                    color: TerminalTheme.matrixGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: TerminalTheme.terminalText.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.packageName,
                    style: TerminalTheme.terminalText.copyWith(
                      color: TerminalTheme.darkGreen,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: TerminalTheme.matrixGreen,
            ),
          ],
        ),
      ),
    );
  }
}