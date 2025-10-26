import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TerminalTheme {
  // Color schemes
  static const Color matrixGreen = Color(0xFF00FF00);
  static const Color darkGreen = Color(0xFF00AA00);
  static const Color cyberCyan = Color(0xFF00FFFF);
  static const Color alertRed = Color(0xFFFF0000);
  static const Color warningYellow = Color(0xFFFFFF00);
  static const Color black = Color(0xFF000000);
  static const Color darkGray = Color(0xFF0A0A0A);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: black,
    primaryColor: matrixGreen,
    textTheme: GoogleFonts.sourceCodeProTextTheme(
      ThemeData.dark().textTheme.apply(
        bodyColor: matrixGreen,
        displayColor: cyberCyan,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: InputBorder.none,
      hintStyle: TextStyle(color: darkGreen),
      contentPadding: EdgeInsets.zero,
    ),
  );

  static TextStyle terminalText = GoogleFonts.sourceCodePro(
    fontSize: 14,
    color: matrixGreen,
    height: 1.5,
  );

  static TextStyle promptText = GoogleFonts.sourceCodePro(
    fontSize: 14,
    color: cyberCyan,
    fontWeight: FontWeight.bold,
  );

  static TextStyle errorText = GoogleFonts.sourceCodePro(
    fontSize: 14,
    color: alertRed,
  );

  static TextStyle warningText = GoogleFonts.sourceCodePro(
    fontSize: 14,
    color: warningYellow,
  );

  // REMOVED BORDERS - Clean look!
  static BoxDecoration terminalDecoration = BoxDecoration(
    color: black,
    // border and boxShadow removed
  );

  static Color getThemeColor(int themeIndex) {
    const colors = [
      matrixGreen, // 0: Matrix Green
      cyberCyan, // 1: Cyber Cyan
      alertRed, // 2: Alert Red
      warningYellow, // 3: Warning Yellow
    ];
    return colors[themeIndex % colors.length];
  }

  static TextStyle getTerminalTextWithColor(Color color) {
    return terminalText.copyWith(color: color);
  }

  static TextStyle getPromptTextWithColor(Color color) {
    return promptText.copyWith(color: color);
  }
}
