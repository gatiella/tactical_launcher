import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/terminal_screen.dart';
import 'screens/gesture_tutorial_screen.dart';
import 'services/shell_service.dart';
import 'services/app_manager_service.dart';
import 'services/package_manager_service.dart';
import 'services/gesture_service.dart';
import 'services/theme_service.dart';
import 'services/ssh_service.dart';
import 'services/backup_service.dart';
import 'services/macro_service.dart';
import 'themes/terminal_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Request permissions
  await _requestPermissions();

  final prefs = await SharedPreferences.getInstance();
  final tutorialCompleted = prefs.getBool('tutorial_completed') ?? false;

  runApp(TacticalLauncher(showTutorial: !tutorialCompleted));
}

Future<void> _requestPermissions() async {
  try {
    // Request storage permissions
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  } catch (e) {
    print('Permission request error: $e');
  }
}

class TacticalLauncher extends StatelessWidget {
  final bool showTutorial;

  const TacticalLauncher({super.key, required this.showTutorial});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShellService()),
        ChangeNotifierProvider(create: (_) => AppManagerService()),
        ChangeNotifierProvider(create: (_) => PackageManagerService()),
        ChangeNotifierProvider(create: (_) => GestureService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => SSHService()),
        ChangeNotifierProvider(create: (_) => BackupService()),
        ChangeNotifierProvider(create: (_) => MacroService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Tactical Launcher',
            debugShowCheckedModeBanner: false,
            theme: TerminalTheme.darkTheme.copyWith(
              primaryColor: themeService.currentThemeColor,
            ),
            home: showTutorial
                ? const GestureTutorialScreen()
                : const TerminalScreen(),
          );
        },
      ),
    );
  }
}
