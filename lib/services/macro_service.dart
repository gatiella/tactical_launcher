import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/macro.dart';

class MacroService extends ChangeNotifier {
  final List<Macro> _macros = [];
  bool _isRecording = false;
  final List<String> _recordingBuffer = [];
  String? _recordingName;

  List<Macro> get macros => List.unmodifiable(_macros);
  bool get isRecording => _isRecording;
  List<String> get recordingBuffer => List.unmodifiable(_recordingBuffer);
  int get recordingCommandCount => _recordingBuffer.length;

  MacroService() {
    _loadMacros();
  }

  Future<void> _loadMacros() async {
    final prefs = await SharedPreferences.getInstance();
    final macrosJson = prefs.getStringList('macros') ?? [];
    
    _macros.clear();
    _macros.addAll(
      macrosJson.map((json) => Macro.fromJson(jsonDecode(json)))
    );
    
    notifyListeners();
  }

  Future<void> _saveMacros() async {
    final prefs = await SharedPreferences.getInstance();
    final macrosJson = _macros
        .map((macro) => jsonEncode(macro.toJson()))
        .toList();
    await prefs.setStringList('macros', macrosJson);
  }

  void startRecording(String name) {
    _isRecording = true;
    _recordingName = name;
    _recordingBuffer.clear();
    notifyListeners();
  }

  void recordCommand(String command) {
    if (_isRecording && command.trim().isNotEmpty) {
      // Don't record macro commands themselves
      if (!command.startsWith('macro ')) {
        _recordingBuffer.add(command);
        notifyListeners();
      }
    }
  }

  Future<Macro?> stopRecording({String? description}) async {
    if (!_isRecording || _recordingName == null) {
      return null;
    }

    if (_recordingBuffer.isEmpty) {
      _isRecording = false;
      _recordingName = null;
      notifyListeners();
      return null;
    }

    final macro = Macro(
      id: 'macro_${DateTime.now().millisecondsSinceEpoch}',
      name: _recordingName!,
      commands: List.from(_recordingBuffer),
      description: description,
    );

    _macros.add(macro);
    await _saveMacros();

    _isRecording = false;
    _recordingName = null;
    _recordingBuffer.clear();
    notifyListeners();

    return macro;
  }

  void cancelRecording() {
    _isRecording = false;
    _recordingName = null;
    _recordingBuffer.clear();
    notifyListeners();
  }

  Future<void> deleteMacro(String id) async {
    _macros.removeWhere((macro) => macro.id == id);
    await _saveMacros();
    notifyListeners();
  }

  Macro? getMacro(String nameOrId) {
    try {
      return _macros.firstWhere(
        (m) => m.name == nameOrId || m.id == nameOrId
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> renameMacro(String id, String newName) async {
    final index = _macros.indexWhere((m) => m.id == id);
    if (index != -1) {
      final oldMacro = _macros[index];
      _macros[index] = Macro(
        id: oldMacro.id,
        name: newName,
        commands: oldMacro.commands,
        created: oldMacro.created,
        description: oldMacro.description,
      );
      await _saveMacros();
      notifyListeners();
    }
  }
}