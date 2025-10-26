import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent;
import 'package:provider/provider.dart';
import '../themes/terminal_theme.dart';
import '../services/shell_service.dart';

class TerminalInput extends StatefulWidget {
  final Function(String) onCommand;

  const TerminalInput({super.key, required this.onCommand});

  @override
  State<TerminalInput> createState() => _TerminalInputState();
}

class _TerminalInputState extends State<TerminalInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _commandHistory = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final command = _controller.text.trim();
    if (command.isNotEmpty) {
      _commandHistory.insert(0, command);
      _historyIndex = -1;
      widget.onCommand(command);
      _controller.clear();
    }
  }

  void _handleArrowUp() {
    if (_commandHistory.isEmpty) return;

    if (_historyIndex < _commandHistory.length - 1) {
      _historyIndex++;
      _controller.text = _commandHistory[_historyIndex];
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  void _handleArrowDown() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _controller.text = _commandHistory[_historyIndex];
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    } else if (_historyIndex == 0) {
      _historyIndex = -1;
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shellService = context.watch<ShellService>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TerminalTheme.darkGray,
        // border removed
      ),
      child: Row(
        children: [
          Text(
            '${shellService.displayPath} \$ ',
            style: TerminalTheme.promptText,
          ),
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey.keyLabel == 'Arrow Up') {
                    _handleArrowUp();
                  } else if (event.logicalKey.keyLabel == 'Arrow Down') {
                    _handleArrowDown();
                  }
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: TerminalTheme.terminalText,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type command...',
                ),
                onSubmitted: (_) => _handleSubmit(),
                autofocus: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
