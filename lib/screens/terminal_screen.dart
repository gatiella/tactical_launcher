import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tactical_launcher/models/terminal_line.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../services/gesture_service.dart';
import '../services/theme_service.dart';
import '../widgets/terminal_widget.dart';
import '../widgets/terminal_input.dart';
import '../widgets/gesture_detector_wrapper.dart';
import '../widgets/system_monitor_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/network_status_widget.dart';
import '../themes/terminal_theme.dart';
import '../commands/command_handler.dart';
import 'app_drawer_screen.dart';
import 'settings_screen.dart';
import 'dart:async';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late CommandHandler _commandHandler;
  late ScrollController _scrollController;
  bool _showWidgets = false;
  Timer? _batteryTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _commandHandler = CommandHandler();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppManagerService>().loadInstalledApps();
      _setupGestures();
    });
  }

  void _setupGestures() {
    final gestureService = context.read<GestureService>();
    final themeService = context.read<ThemeService>();
    final shellService = context.read<ShellService>();

    gestureService.onSwipeUp = () {
      setState(() {
        _showWidgets = !_showWidgets;
      });
    };

    gestureService.onSwipeDown = () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AppDrawerScreen()),
      );
    };

    gestureService.onSwipeLeft = () {
      themeService.previousTheme();
      shellService.addOutput(
        '◀ Theme: ${themeService.currentThemeName}',
        type: LineType.info,
      );
    };

    gestureService.onSwipeRight = () {
      themeService.nextTheme();
      shellService.addOutput(
        '▶ Theme: ${themeService.currentThemeName}',
        type: LineType.info,
      );
    };

    gestureService.onDoubleTap = () {
      shellService.clear();
    };

    gestureService.onLongPress = () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _batteryTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleCommand(String command) async {
    final shellService = context.read<ShellService>();
    final appService = context.read<AppManagerService>();
    
    await _commandHandler.handleCommand(
      command,
      shellService,
      appService,
    );
    
    _scrollToBottom();
  }

  void _toggleWidgets() {
    setState(() {
      _showWidgets = !_showWidgets;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gestureService = context.watch<GestureService>();
    final themeService = context.watch<ThemeService>();

    return GestureDetectorWrapper(
      gestureService: gestureService,
      child: Scaffold(
        backgroundColor: TerminalTheme.black,
        body: SafeArea(
          top: false,
          child: Container(
            decoration: TerminalTheme.terminalDecoration.copyWith(
              border: Border.all(
                color: themeService.currentThemeColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeService.currentThemeColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(themeService),
                
                if (_showWidgets) ...[
                  const SystemMonitorWidget(),
                  QuickActionsWidget(onCommand: _handleCommand),
                  Divider(color: themeService.currentThemeColor),
                ],
                
                Expanded(
                  child: Consumer<ShellService>(
                    builder: (context, shellService, child) {
                      return TerminalWidget(
                        history: shellService.history,
                        scrollController: _scrollController,
                      );
                    },
                  ),
                ),
                
                TerminalInput(
                  onCommand: _handleCommand,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildGestureHelp(),
      ),
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: TerminalTheme.black,
        border: Border(
          bottom: BorderSide(
            color: themeService.currentThemeColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'TACTICAL OS v2.1',
                    style: TerminalTheme.promptText.copyWith(
                      color: themeService.currentThemeColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const NetworkStatusWidget(),
              ],
            ),
          ),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.widgets,
                  color: themeService.currentThemeColor,
                ),
                onPressed: _toggleWidgets,
                iconSize: 20,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                tooltip: 'Toggle Widgets',
              ),
              const SizedBox(width: 8),
              Text(
                TimeOfDay.now().format(context),
                style: TerminalTheme.terminalText.copyWith(
                  color: themeService.currentThemeColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGestureHelp() {
    return FloatingActionButton(
      mini: true,
      backgroundColor: TerminalTheme.matrixGreen.withOpacity(0.2),
      onPressed: _showGestureGuide,
      child: Icon(
        Icons.help_outline,
        color: TerminalTheme.matrixGreen,
        size: 20,
      ),
    );
  }

  void _showGestureGuide() {
    final themeService = context.read<ThemeService>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TerminalTheme.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: themeService.currentThemeColor,
            width: 2,
          ),
        ),
        title: Text(
          '⚡ GESTURE CONTROLS',
          style: TerminalTheme.promptText.copyWith(
            color: themeService.currentThemeColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGestureItem('↑ Swipe Up', 'Toggle Widgets'),
            _buildGestureItem('↓ Swipe Down', 'Open App Drawer'),
            _buildGestureItem('← Swipe Left', 'Previous Theme'),
            _buildGestureItem('→ Swipe Right', 'Next Theme'),
            _buildGestureItem('⚡ Double Tap', 'Clear Terminal'),
            _buildGestureItem('⏸ Long Press', 'Open Settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'GOT IT',
              style: TerminalTheme.promptText.copyWith(
                color: themeService.currentThemeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureItem(String gesture, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              gesture,
              style: TerminalTheme.promptText.copyWith(fontSize: 14),
            ),
          ),
          Text(
            action,
            style: TerminalTheme.terminalText.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}