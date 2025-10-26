import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../themes/terminal_theme.dart';

class NanoEditorScreen extends StatefulWidget {
  final String? filePath;
  final String? initialContent;

  const NanoEditorScreen({super.key, this.filePath, this.initialContent});

  @override
  State<NanoEditorScreen> createState() => _NanoEditorScreenState();
}

class _NanoEditorScreenState extends State<NanoEditorScreen> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  String _filename = 'untitled.txt';
  bool _hasUnsavedChanges = false;
  int _currentLine = 1;
  int _currentColumn = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent ?? '');
    _scrollController = ScrollController();

    if (widget.filePath != null) {
      _filename = widget.filePath!.split('/').last;
      _loadFile();
    }

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    try {
      final file = File(widget.filePath!);
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _controller.text = content;
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      _showMessage('Error loading file: $e');
    }
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = true;
      _updateCursorPosition();
    });
  }

  void _updateCursorPosition() {
    final selection = _controller.selection;
    final text = _controller.text.substring(0, selection.start);
    final lines = text.split('\n');
    _currentLine = lines.length;
    _currentColumn = lines.last.length;
  }

  Future<void> _saveFile() async {
    try {
      String savePath;

      if (widget.filePath != null) {
        savePath = widget.filePath!;
      } else {
        // Use accessible directory
        final appDir = await getApplicationDocumentsDirectory();
        savePath = '${appDir.path}/$_filename';

        // Ask user for custom path if needed
        final result = await _showSaveDialog();
        if (result != null) {
          savePath = result;
        }
      }

      final file = File(savePath);

      // Create parent directory if it doesn't exist
      final parentDir = Directory(file.parent.path);
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await file.writeAsString(_controller.text);

      setState(() {
        _hasUnsavedChanges = false;
        _filename = savePath.split('/').last;
      });

      _showMessage('✓ File saved: $_filename');
    } catch (e) {
      _showMessage('✗ Error saving: $e');
    }
  }

  Future<String?> _showSaveDialog() async {
    final appDir = await getApplicationDocumentsDirectory();
    final controller = TextEditingController(text: _filename);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TerminalTheme.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: TerminalTheme.matrixGreen, width: 2),
        ),
        title: Text('Save File', style: TerminalTheme.promptText),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save to: ${appDir.path}/',
              style: TerminalTheme.terminalText.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: TerminalTheme.terminalText,
              decoration: InputDecoration(
                labelText: 'Filename',
                labelStyle: TerminalTheme.terminalText,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: TerminalTheme.matrixGreen),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: TerminalTheme.matrixGreen),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accessible paths:',
              style: TerminalTheme.terminalText.copyWith(fontSize: 10),
            ),
            Text(
              '• App directory (recommended)',
              style: TerminalTheme.terminalText.copyWith(
                fontSize: 10,
                color: TerminalTheme.darkGreen,
              ),
            ),
            Text(
              '• /storage/emulated/0/Download',
              style: TerminalTheme.terminalText.copyWith(
                fontSize: 10,
                color: TerminalTheme.darkGreen,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TerminalTheme.terminalText),
          ),
          TextButton(
            onPressed: () {
              final filename = controller.text.trim();
              if (filename.isNotEmpty) {
                Navigator.pop(context, '${appDir.path}/$filename');
              }
            },
            child: Text('Save', style: TerminalTheme.promptText),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TerminalTheme.terminalText),
        backgroundColor: TerminalTheme.darkGray,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TerminalTheme.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: TerminalTheme.alertRed, width: 2),
        ),
        title: Text('Unsaved Changes', style: TerminalTheme.promptText),
        content: Text(
          'Save changes before closing?',
          style: TerminalTheme.terminalText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Don't Save", style: TerminalTheme.errorText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TerminalTheme.terminalText),
          ),
          TextButton(
            onPressed: () async {
              await _saveFile();
              if (mounted) Navigator.pop(context, true);
            },
            child: Text('Save', style: TerminalTheme.promptText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: TerminalTheme.black,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildToolbar(),
            Expanded(child: _buildEditor()),
            _buildStatusBar(),
            _buildShortcutBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: TerminalTheme.darkGray,
      title: Row(
        children: [
          Text('NANO EDITOR', style: TerminalTheme.promptText),
          const SizedBox(width: 8),
          Text(
            '- $_filename',
            style: TerminalTheme.terminalText.copyWith(fontSize: 14),
          ),
          if (_hasUnsavedChanges)
            Text(
              ' [Modified]',
              style: TerminalTheme.terminalText.copyWith(
                color: TerminalTheme.warningYellow,
                fontSize: 12,
              ),
            ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: TerminalTheme.matrixGreen),
        onPressed: () async {
          if (await _onWillPop()) {
            if (mounted) Navigator.pop(context);
          }
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.save, color: TerminalTheme.matrixGreen),
          onPressed: _saveFile,
          tooltip: 'Save (Ctrl+O)',
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TerminalTheme.darkGray,
        border: Border(
          bottom: BorderSide(color: TerminalTheme.matrixGreen, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(Icons.save, 'Save', _saveFile),
          _buildToolbarButton(Icons.undo, 'Undo', _undo),
          _buildToolbarButton(Icons.redo, 'Redo', _redo),
          _buildToolbarButton(Icons.search, 'Find', _showFindDialog),
          _buildToolbarButton(Icons.format_indent_increase, 'Indent', _indent),
          const Spacer(),
          Text(
            _getFileTypeLabel(),
            style: TerminalTheme.terminalText.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return IconButton(
      icon: Icon(icon, color: TerminalTheme.matrixGreen, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(8),
    );
  }

  Widget _buildEditor() {
    return Container(
      color: TerminalTheme.black,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLineNumbers(),
          Expanded(
            child: TextField(
              controller: _controller,
              scrollController: _scrollController,
              maxLines: null,
              expands: true,
              style: TerminalTheme.terminalText.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Start typing...',
                hintStyle: TextStyle(color: TerminalTheme.darkGreen),
              ),
              cursorColor: TerminalTheme.matrixGreen,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineNumbers() {
    final lineCount = _controller.text.split('\n').length;

    return Container(
      width: 50,
      color: TerminalTheme.darkGray,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          lineCount,
          (index) => Text(
            '${index + 1}',
            style: TerminalTheme.terminalText.copyWith(
              color: TerminalTheme.darkGreen,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: TerminalTheme.darkGray,
        border: Border(
          top: BorderSide(color: TerminalTheme.matrixGreen, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Line $_currentLine, Col $_currentColumn',
            style: TerminalTheme.terminalText.copyWith(fontSize: 12),
          ),
          Text(
            '${_controller.text.length} chars | ${_controller.text.split('\n').length} lines',
            style: TerminalTheme.terminalText.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TerminalTheme.darkGray,
        border: Border(
          top: BorderSide(color: TerminalTheme.matrixGreen, width: 1),
        ),
      ),
      child: Wrap(
        spacing: 16,
        children: [
          _buildShortcut('Ctrl+O', 'Save'),
          _buildShortcut('Ctrl+X', 'Exit'),
          _buildShortcut('Ctrl+W', 'Find'),
          _buildShortcut('Ctrl+K', 'Cut'),
          _buildShortcut('Ctrl+U', 'Paste'),
        ],
      ),
    );
  }

  Widget _buildShortcut(String key, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(key, style: TerminalTheme.promptText.copyWith(fontSize: 10)),
        const SizedBox(width: 4),
        Text(action, style: TerminalTheme.terminalText.copyWith(fontSize: 10)),
      ],
    );
  }

  String _getFileTypeLabel() {
    final ext = _filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
        return 'Dart';
      case 'py':
        return 'Python';
      case 'go':
        return 'Go';
      case 'js':
        return 'JavaScript';
      case 'java':
        return 'Java';
      case 'cpp':
      case 'c':
        return 'C/C++';
      default:
        return 'Text';
    }
  }

  void _undo() {
    // Implement undo logic
    _showMessage('Undo not yet implemented');
  }

  void _redo() {
    // Implement redo logic
    _showMessage('Redo not yet implemented');
  }

  void _indent() {
    final selection = _controller.selection;
    if (selection.isValid) {
      final text = _controller.text;
      final start = selection.start;

      // Add 2 spaces at cursor
      final newText = text.substring(0, start) + '  ' + text.substring(start);
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(offset: start + 2);
    }
  }

  void _showFindDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TerminalTheme.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: TerminalTheme.matrixGreen, width: 2),
        ),
        title: Text('Find', style: TerminalTheme.promptText),
        content: TextField(
          style: TerminalTheme.terminalText,
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: TerminalTheme.darkGreen),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: TerminalTheme.matrixGreen),
            ),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            _findText(value);
          },
        ),
      ),
    );
  }

  void _findText(String query) {
    if (query.isEmpty) return;

    final text = _controller.text.toLowerCase();
    final index = text.indexOf(query.toLowerCase());

    if (index != -1) {
      _controller.selection = TextSelection(
        baseOffset: index,
        extentOffset: index + query.length,
      );
      _showMessage('Found at position $index');
    } else {
      _showMessage('Not found');
    }
  }
}
