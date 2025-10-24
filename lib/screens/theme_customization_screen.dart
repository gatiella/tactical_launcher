import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/theme_service.dart';
import '../models/custom_theme.dart';
import '../themes/terminal_theme.dart';

class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  State<ThemeCustomizationScreen> createState() => _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends State<ThemeCustomizationScreen> {
  final TextEditingController _nameController = TextEditingController();
  Color _primaryColor = const Color(0xFF00FF00);
  Color _secondaryColor = const Color(0xFF00AA00);
  Color _backgroundColor = const Color(0xFF000000);
  Color _textColor = const Color(0xFF00FF00);
  Color _accentColor = const Color(0xFF00FFFF);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _pickColor(String colorType, Color currentColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TerminalTheme.black,
        title: Text(
          'Pick $colorType Color',
          style: TerminalTheme.promptText,
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              setState(() {
                switch (colorType) {
                  case 'Primary':
                    _primaryColor = color;
                    break;
                  case 'Secondary':
                    _secondaryColor = color;
                    break;
                  case 'Background':
                    _backgroundColor = color;
                    break;
                  case 'Text':
                    _textColor = color;
                    break;
                  case 'Accent':
                    _accentColor = color;
                    break;
                }
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done', style: TerminalTheme.promptText),
          ),
        ],
      ),
    );
  }

  void _saveTheme() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a theme name', style: TerminalTheme.terminalText),
          backgroundColor: TerminalTheme.alertRed,
        ),
      );
      return;
    }

    final theme = CustomTheme(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      backgroundColor: _backgroundColor,
      textColor: _textColor,
      accentColor: _accentColor,
      isCustom: true,
    );

    context.read<ThemeService>().addCustomTheme(theme);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TerminalTheme.black,
      body: SafeArea(
        child: Container(
          decoration: TerminalTheme.terminalDecoration,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildNameInput(),
                    const SizedBox(height: 24),
                    _buildPreview(),
                    const SizedBox(height: 24),
                    _buildColorPickers(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            'CREATE CUSTOM THEME',
            style: TerminalTheme.promptText,
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      style: TerminalTheme.terminalText,
      decoration: InputDecoration(
        labelText: 'Theme Name',
        labelStyle: TerminalTheme.terminalText,
        hintText: 'Enter theme name...',
        hintStyle: TextStyle(color: TerminalTheme.darkGreen),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: TerminalTheme.matrixGreen),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: TerminalTheme.matrixGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: TerminalTheme.cyberCyan, width: 2),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border.all(color: _primaryColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREVIEW',
            style: TextStyle(color: _accentColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'root@tactical:~\$ ',
            style: TextStyle(color: _primaryColor, fontSize: 14),
          ),
          Text(
            'This is how your theme will look',
            style: TextStyle(color: _textColor, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _secondaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickers() {
    return Column(
      children: [
        _buildColorOption('Primary Color', _primaryColor, 'Primary'),
        _buildColorOption('Secondary Color', _secondaryColor, 'Secondary'),
        _buildColorOption('Background Color', _backgroundColor, 'Background'),
        _buildColorOption('Text Color', _textColor, 'Text'),
        _buildColorOption('Accent Color', _accentColor, 'Accent'),
      ],
    );
  }

  Widget _buildColorOption(String label, Color color, String colorType) {
    return InkWell(
      onTap: () => _pickColor(colorType, color),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: TerminalTheme.matrixGreen),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TerminalTheme.terminalText),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: TerminalTheme.matrixGreen, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit, color: TerminalTheme.matrixGreen, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveTheme,
      style: ElevatedButton.styleFrom(
        backgroundColor: TerminalTheme.matrixGreen.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: TerminalTheme.matrixGreen, width: 2),
        ),
      ),
      child: Text(
        'CREATE THEME',
        style: TerminalTheme.promptText.copyWith(fontSize: 16),
      ),
    );
  }
}