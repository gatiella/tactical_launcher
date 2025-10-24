import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/custom_theme.dart';

class ThemeService extends ChangeNotifier {
  List<CustomTheme> _themes = CustomTheme.presetThemes;
  int _currentThemeIndex = 0;
  CustomTheme? _activeCustomTheme;

  List<CustomTheme> get themes => List.unmodifiable(_themes);
  int get currentThemeIndex => _currentThemeIndex;
  CustomTheme get currentTheme => _activeCustomTheme ?? _themes[_currentThemeIndex];
  String get currentThemeName => currentTheme.name;
  Color get currentThemeColor => currentTheme.primaryColor;

  ThemeService() {
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme index
    _currentThemeIndex = prefs.getInt('theme_index') ?? 0;
    
    // Load custom themes
    final customThemesJson = prefs.getStringList('custom_themes') ?? [];
    final customThemes = customThemesJson
        .map((json) => CustomTheme.fromJson(jsonDecode(json)))
        .toList();
    
    _themes = [...CustomTheme.presetThemes, ...customThemes];
    
    // Load active custom theme if exists
    final activeCustomJson = prefs.getString('active_custom_theme');
    if (activeCustomJson != null) {
      _activeCustomTheme = CustomTheme.fromJson(jsonDecode(activeCustomJson));
    }
    
    notifyListeners();
  }

  Future<void> _saveThemes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', _currentThemeIndex);
    
    // Save custom themes
    final customThemes = _themes.where((t) => t.isCustom).toList();
    final customThemesJson = customThemes
        .map((t) => jsonEncode(t.toJson()))
        .toList();
    await prefs.setStringList('custom_themes', customThemesJson);
    
    // Save active custom theme
    if (_activeCustomTheme != null) {
      await prefs.setString(
        'active_custom_theme',
        jsonEncode(_activeCustomTheme!.toJson()),
      );
    }
  }

  Future<void> nextTheme() async {
    _currentThemeIndex = (_currentThemeIndex + 1) % _themes.length;
    _activeCustomTheme = null;
    await _saveThemes();
    notifyListeners();
  }

  Future<void> previousTheme() async {
    _currentThemeIndex = (_currentThemeIndex - 1 + _themes.length) % _themes.length;
    _activeCustomTheme = null;
    await _saveThemes();
    notifyListeners();
  }

  Future<void> setTheme(int index) async {
    if (index >= 0 && index < _themes.length) {
      _currentThemeIndex = index;
      _activeCustomTheme = null;
      await _saveThemes();
      notifyListeners();
    }
  }

  Future<void> addCustomTheme(CustomTheme theme) async {
    _themes.add(theme);
    _currentThemeIndex = _themes.length - 1;
    _activeCustomTheme = theme;
    await _saveThemes();
    notifyListeners();
  }

  Future<void> deleteCustomTheme(String themeId) async {
    _themes.removeWhere((t) => t.id == themeId && t.isCustom);
    if (_currentThemeIndex >= _themes.length) {
      _currentThemeIndex = 0;
    }
    await _saveThemes();
    notifyListeners();
  }

  Future<void> updateCustomTheme(CustomTheme theme) async {
    final index = _themes.indexWhere((t) => t.id == theme.id);
    if (index != -1) {
      _themes[index] = theme;
      if (_activeCustomTheme?.id == theme.id) {
        _activeCustomTheme = theme;
      }
      await _saveThemes();
      notifyListeners();
    }
  }
}