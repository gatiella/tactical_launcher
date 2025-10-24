import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactical_launcher/screens/theme_customization_screen.dart';
import 'package:tactical_launcher/screens/theme_manager_screen.dart';
import '../themes/terminal_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentTheme = 'matrix_green';
  double _fontSize = 14.0;
  bool _showSystemApps = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString('theme') ?? 'matrix_green';
      _fontSize = prefs.getDouble('fontSize') ?? 14.0;
      _showSystemApps = prefs.getBool('showSystemApps') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _currentTheme);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setBool('showSystemApps', _showSystemApps);
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
                    _buildThemeSection(),
                    const SizedBox(height: 24),
                    _buildDisplaySection(),
                    const SizedBox(height: 24),
                    _buildAppSection(),
                    const SizedBox(height: 24),
                    _buildAboutSection(),
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
            'SETTINGS',
            style: TerminalTheme.promptText,
          ),
        ],
      ),
    );
  }

Widget _buildThemeSection() {
  return _buildSection(
    title: 'THEME',
    children: [
      ListTile(
        leading: Icon(Icons.palette, color: TerminalTheme.matrixGreen),
        title: Text('Theme Manager', style: TerminalTheme.terminalText),
        subtitle: Text('Manage and create themes', style: TextStyle(color: TerminalTheme.darkGreen)),
        trailing: Icon(Icons.chevron_right, color: TerminalTheme.matrixGreen),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ThemeManagerScreen()),
          );
        },
      ),
      ListTile(
        leading: Icon(Icons.add_box, color: TerminalTheme.matrixGreen),
        title: Text('Create Custom Theme', style: TerminalTheme.terminalText),
        subtitle: Text('Design your own theme', style: TextStyle(color: TerminalTheme.darkGreen)),
        trailing: Icon(Icons.chevron_right, color: TerminalTheme.matrixGreen),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ThemeCustomizationScreen()),
          );
        },
      ),
    ],
  );
}

  Widget _buildDisplaySection() {
    return _buildSection(
      title: 'DISPLAY',
      children: [
        ListTile(
          title: Text('Font Size', style: TerminalTheme.terminalText),
          subtitle: Slider(
            value: _fontSize,
            min: 10,
            max: 20,
            divisions: 10,
            activeColor: TerminalTheme.matrixGreen,
            inactiveColor: TerminalTheme.darkGreen,
            label: _fontSize.round().toString(),
            onChanged: (value) {
              setState(() {
                _fontSize = value;
              });
              _saveSettings();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppSection() {
    return _buildSection(
      title: 'APPLICATIONS',
      children: [
        SwitchListTile(
          title: Text('Show System Apps', style: TerminalTheme.terminalText),
          value: _showSystemApps,
          activeColor: TerminalTheme.matrixGreen,
          onChanged: (value) {
            setState(() {
              _showSystemApps = value;
            });
            _saveSettings();
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'ABOUT',
      children: [
        ListTile(
          title: Text('Version', style: TerminalTheme.terminalText),
          subtitle: Text('2.1.0', style: TextStyle(color: TerminalTheme.darkGreen)),
        ),
        ListTile(
          title: Text('Developer', style: TerminalTheme.terminalText),
          subtitle: Text('Tactical OS Team', style: TextStyle(color: TerminalTheme.darkGreen)),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: TerminalTheme.matrixGreen, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TerminalTheme.promptText,
            ),
          ),
          Divider(color: TerminalTheme.matrixGreen, height: 1),
          ...children,
        ],
      ),
    );
  }

  // Widget _buildThemeOption(String name, String value, Color color) {
  //   return RadioListTile<String>(
  //     title: Row(
  //       children: [
  //         Container(
  //           width: 24,
  //           height: 24,
  //           decoration: BoxDecoration(
  //             color: color,
  //             border: Border.all(color: color, width: 2),
  //             borderRadius: BorderRadius.circular(4),
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Text(name, style: TerminalTheme.terminalText),
  //       ],
  //     ),
  //     value: value,
  //     groupValue: _currentTheme,
  //     activeColor: TerminalTheme.matrixGreen,
  //     onChanged: (value) {
  //       setState(() {
  //         _currentTheme = value!;
  //       });
  //       _saveSettings();
  //     },
  //   );
  // }
}