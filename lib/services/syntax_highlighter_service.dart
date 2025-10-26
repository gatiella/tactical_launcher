import 'package:flutter/material.dart';
import '../themes/terminal_theme.dart';

class SyntaxHighlighterService {
  static const Map<String, List<String>> _keywords = {
    'dart': [
      'class',
      'void',
      'int',
      'String',
      'bool',
      'var',
      'final',
      'const',
      'if',
      'else',
      'for',
      'while',
      'return',
      'import',
      'export',
      'async',
      'await',
    ],
    'python': [
      'def',
      'class',
      'if',
      'elif',
      'else',
      'for',
      'while',
      'return',
      'import',
      'from',
      'as',
      'try',
      'except',
      'with',
      'lambda',
      'yield',
    ],
    'go': [
      'func',
      'package',
      'import',
      'var',
      'const',
      'if',
      'else',
      'for',
      'range',
      'return',
      'type',
      'struct',
      'interface',
      'go',
      'defer',
    ],
    'javascript': [
      'function',
      'var',
      'let',
      'const',
      'if',
      'else',
      'for',
      'while',
      'return',
      'class',
      'import',
      'export',
      'async',
      'await',
    ],
  };

  TextSpan highlight(String code, String language) {
    final keywords = _keywords[language.toLowerCase()] ?? [];
    final spans = <TextSpan>[];

    // Simple syntax highlighting
    final words = code.split(RegExp(r'(\s+)'));

    for (var word in words) {
      if (keywords.contains(word)) {
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(
              color: TerminalTheme.cyberCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (word.startsWith('//') || word.startsWith('#')) {
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(
              color: TerminalTheme.darkGreen,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else if (word.startsWith('"') || word.startsWith("'")) {
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(color: TerminalTheme.warningYellow),
          ),
        );
      } else {
        spans.add(TextSpan(text: word, style: TerminalTheme.terminalText));
      }
    }

    return TextSpan(children: spans);
  }
}
