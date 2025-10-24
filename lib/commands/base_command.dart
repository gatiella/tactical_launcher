import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../models/command_result.dart';

abstract class BaseCommand {
  String get name;
  String get description;
  String get usage;

  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  );

  void printHelp(ShellService shellService) {
    shellService.addOutput('Usage: $usage');
    shellService.addOutput(description);
  }
}