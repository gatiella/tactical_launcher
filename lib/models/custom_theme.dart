import 'package:flutter/material.dart';

class CustomTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final bool isCustom;

  CustomTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'primaryColor': primaryColor.value,
    'secondaryColor': secondaryColor.value,
    'backgroundColor': backgroundColor.value,
    'textColor': textColor.value,
    'accentColor': accentColor.value,
    'isCustom': isCustom,
  };

  factory CustomTheme.fromJson(Map<String, dynamic> json) => CustomTheme(
    id: json['id'],
    name: json['name'],
    primaryColor: Color(json['primaryColor']),
    secondaryColor: Color(json['secondaryColor']),
    backgroundColor: Color(json['backgroundColor']),
    textColor: Color(json['textColor']),
    accentColor: Color(json['accentColor']),
    isCustom: json['isCustom'] ?? false,
  );

  // Preset themes
  static CustomTheme get matrixGreen => CustomTheme(
    id: 'matrix_green',
    name: 'Matrix Green',
    primaryColor: const Color(0xFF00FF00),
    secondaryColor: const Color(0xFF00AA00),
    backgroundColor: const Color(0xFF000000),
    textColor: const Color(0xFF00FF00),
    accentColor: const Color(0xFF00FFFF),
  );

  static CustomTheme get cyberCyan => CustomTheme(
    id: 'cyber_cyan',
    name: 'Cyber Cyan',
    primaryColor: const Color(0xFF00FFFF),
    secondaryColor: const Color(0xFF0088AA),
    backgroundColor: const Color(0xFF000000),
    textColor: const Color(0xFF00FFFF),
    accentColor: const Color(0xFF00FF00),
  );

  static CustomTheme get alertRed => CustomTheme(
    id: 'alert_red',
    name: 'Alert Red',
    primaryColor: const Color(0xFFFF0000),
    secondaryColor: const Color(0xFFAA0000),
    backgroundColor: const Color(0xFF000000),
    textColor: const Color(0xFFFF0000),
    accentColor: const Color(0xFFFFFF00),
  );

  static CustomTheme get warningYellow => CustomTheme(
    id: 'warning_yellow',
    name: 'Warning Yellow',
    primaryColor: const Color(0xFFFFFF00),
    secondaryColor: const Color(0xFFAAAA00),
    backgroundColor: const Color(0xFF000000),
    textColor: const Color(0xFFFFFF00),
    accentColor: const Color(0xFFFF00FF),
  );

  static CustomTheme get tacticalPurple => CustomTheme(
    id: 'tactical_purple',
    name: 'Tactical Purple',
    primaryColor: const Color(0xFFAA00FF),
    secondaryColor: const Color(0xFF6600AA),
    backgroundColor: const Color(0xFF000000),
    textColor: const Color(0xFFAA00FF),
    accentColor: const Color(0xFF00FFFF),
  );

  static CustomTheme get neonPink => CustomTheme(
    id: 'neon_pink',
    name: 'Neon Pink',
    primaryColor: const Color(0xFFFF00FF),
    secondaryColor: const Color(0xFFAA0088),
    backgroundColor: const Color(0xFF000000),
    textColor: const Color(0xFFFF00FF),
    accentColor: const Color(0xFF00FF00),
  );

  static List<CustomTheme> get presetThemes => [
    matrixGreen,
    cyberCyan,
    alertRed,
    warningYellow,
    tacticalPurple,
    neonPink,
  ];
}