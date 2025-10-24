import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../themes/terminal_theme.dart';
import 'theme_customization_screen.dart';

class ThemeManagerScreen extends StatelessWidget {
  const ThemeManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TerminalTheme.black,
      body: SafeArea(
        child: Container(
          decoration: TerminalTheme.terminalDecoration,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: themeService.themes.length,
                      itemBuilder: (context, index) {
                        final theme = themeService.themes[index];
                        final isActive = index == themeService.currentThemeIndex;
                        return _buildThemeCard(context, theme, isActive, index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ThemeCustomizationScreen()),
          );
        },
        backgroundColor: TerminalTheme.matrixGreen.withOpacity(0.2),
        icon: Icon(Icons.add, color: TerminalTheme.matrixGreen),
        label: Text('CREATE THEME', style: TerminalTheme.promptText),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: TerminalTheme.matrixGreen, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: TerminalTheme.matrixGreen),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'THEME MANAGER',
            style: TerminalTheme.promptText,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, theme, bool isActive, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? theme.primaryColor : TerminalTheme.matrixGreen,
          width: isActive ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isActive ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.secondaryColor],
            ),
            border: Border.all(color: theme.primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        title: Text(
          theme.name,
          style: TerminalTheme.terminalText.copyWith(
            color: theme.primaryColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          theme.isCustom ? 'Custom Theme' : 'Preset Theme',
          style: TerminalTheme.terminalText.copyWith(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Icon(Icons.check_circle, color: theme.primaryColor),
            if (theme.isCustom) ...[
              IconButton(
                icon: Icon(Icons.delete, color: TerminalTheme.alertRed),
                onPressed: () => _deleteTheme(context, theme.id),
              ),
            ],
          ],
        ),
        onTap: () {
          context.read<ThemeService>().setTheme(index);
        },
      ),
    );
  }

  void _deleteTheme(BuildContext context, String themeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TerminalTheme.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: TerminalTheme.alertRed, width: 2),
        ),
        title: Text('Delete Theme?', style: TerminalTheme.promptText),
        content: Text(
          'This action cannot be undone.',
          style: TerminalTheme.terminalText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TerminalTheme.terminalText),
          ),
          TextButton(
            onPressed: () {
              context.read<ThemeService>().deleteCustomTheme(themeId);
              Navigator.pop(context);
            },
            child: Text(
              'DELETE',
              style: TerminalTheme.terminalText.copyWith(color: TerminalTheme.alertRed),
            ),
          ),
        ],
      ),
    );
  }
}