import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../services/macro_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';

class MacroCommand extends BaseCommand {
  final MacroService macroService;

  MacroCommand(this.macroService);

  @override
  String get name => 'macro';

  @override
  String get description => 'Record and run command macros';

  @override
  String get usage => 'macro <record|stop|list|run|delete> [name]';

  @override
  Future<CommandResult> execute(
    List<String> args,
    ShellService shellService,
    AppManagerService appService,
  ) async {
    if (args.isEmpty) {
      printHelp(shellService);
      return CommandResult.error('No action specified');
    }

    final action = args[0];

    switch (action) {
      case 'record':
        if (args.length < 2) {
          shellService.addOutput('Usage: macro record <name>', type: LineType.error);
          return CommandResult.error('No name specified');
        }
        return await _startRecording(args[1], shellService);
      
      case 'stop':
        return await _stopRecording(shellService);
      
      case 'cancel':
        return await _cancelRecording(shellService);
      
      case 'list':
        return await _listMacros(shellService);
      
      case 'run':
        if (args.length < 2) {
          shellService.addOutput('Usage: macro run <name>', type: LineType.error);
          return CommandResult.error('No macro specified');
        }
        return await _runMacro(args[1], shellService);
      
      case 'delete':
        if (args.length < 2) {
          shellService.addOutput('Usage: macro delete <name>', type: LineType.error);
          return CommandResult.error('No macro specified');
        }
        return await _deleteMacro(args[1], shellService);
      
      case 'show':
        if (args.length < 2) {
          shellService.addOutput('Usage: macro show <name>', type: LineType.error);
          return CommandResult.error('No macro specified');
        }
        return await _showMacro(args[1], shellService);
      
      case 'status':
        return await _showStatus(shellService);
      
      default:
        shellService.addOutput('Unknown action: $action', type: LineType.error);
        printHelp(shellService);
        return CommandResult.error('Unknown action');
    }
  }

  Future<CommandResult> _startRecording(String name, ShellService shellService) async {
    if (macroService.isRecording) {
      shellService.addOutput('Already recording a macro', type: LineType.warning);
      shellService.addOutput('Stop current recording: macro stop');
      return CommandResult.error('Already recording');
    }

    macroService.startRecording(name);
    shellService.addOutput('● Recording macro: $name', type: LineType.success);
    shellService.addOutput('  Commands will be recorded automatically');
    shellService.addOutput('  Stop recording: macro stop');
    shellService.addOutput('  Cancel recording: macro cancel');
    
    return CommandResult.success('Recording started');
  }

  Future<CommandResult> _stopRecording(ShellService shellService) async {
    if (!macroService.isRecording) {
      shellService.addOutput('Not recording any macro', type: LineType.warning);
      return CommandResult.error('Not recording');
    }

    final commandCount = macroService.recordingCommandCount;
    
    if (commandCount == 0) {
      shellService.addOutput('No commands recorded', type: LineType.warning);
      macroService.cancelRecording();
      return CommandResult.error('No commands');
    }

    final macro = await macroService.stopRecording();
    
    if (macro != null) {
      shellService.addOutput('✓ Macro saved: ${macro.name}', type: LineType.success);
      shellService.addOutput('  Commands: ${macro.commands.length}');
      shellService.addOutput('  Run with: macro run ${macro.name}');
      return CommandResult.success('Macro saved');
    } else {
      shellService.addOutput('✗ Failed to save macro', type: LineType.error);
      return CommandResult.error('Save failed');
    }
  }

  Future<CommandResult> _cancelRecording(ShellService shellService) async {
    if (!macroService.isRecording) {
      shellService.addOutput('Not recording any macro', type: LineType.warning);
      return CommandResult.error('Not recording');
    }

    macroService.cancelRecording();
    shellService.addOutput('✓ Recording cancelled', type: LineType.success);
    return CommandResult.success('Recording cancelled');
  }

  Future<CommandResult> _listMacros(ShellService shellService) async {
    final macros = macroService.macros;
    
    if (macros.isEmpty) {
      shellService.addOutput('No macros saved', type: LineType.info);
      shellService.addOutput('Record macro: macro record <name>');
      return CommandResult.success('No macros');
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('SAVED MACROS', type: LineType.info);
    shellService.addOutput('═' * 50);

    for (var i = 0; i < macros.length; i++) {
      final macro = macros[i];
      shellService.addOutput('[$i] ${macro.name}');
      shellService.addOutput('    ${macro.commands.length} commands | Created: ${_formatDate(macro.created)}', 
        type: LineType.info);
      if (macro.description != null) {
        shellService.addOutput('    ${macro.description}', type: LineType.info);
      }
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('Run: macro run <name>');
    
    return CommandResult.success('Listed ${macros.length} macros');
  }

  Future<CommandResult> _runMacro(String name, ShellService shellService) async {
    final macro = macroService.getMacro(name);
    
    if (macro == null) {
      shellService.addOutput('Macro not found: $name', type: LineType.error);
      return CommandResult.error('Macro not found');
    }

    shellService.addOutput('▸ Running macro: ${macro.name}', type: LineType.info);
    shellService.addOutput('  Executing ${macro.commands.length} commands...');
    shellService.addOutput('═' * 50);

    // Note: Actual execution should be handled by the command handler
    // This just displays what would be executed
    for (var i = 0; i < macro.commands.length; i++) {
      shellService.addOutput('[$i] ${macro.commands[i]}', type: LineType.info);
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('✓ Macro execution queued', type: LineType.success);
    shellService.addOutput('  Commands will execute in sequence');
    
    return CommandResult.success('Macro queued: ${macro.commands.join(";")}');
  }

  Future<CommandResult> _deleteMacro(String name, ShellService shellService) async {
    final macro = macroService.getMacro(name);
    
    if (macro == null) {
      shellService.addOutput('Macro not found: $name', type: LineType.error);
      return CommandResult.error('Macro not found');
    }

    await macroService.deleteMacro(macro.id);
    shellService.addOutput('✓ Macro deleted: ${macro.name}', type: LineType.success);
    
    return CommandResult.success('Macro deleted');
  }

  Future<CommandResult> _showMacro(String name, ShellService shellService) async {
    final macro = macroService.getMacro(name);
    
    if (macro == null) {
      shellService.addOutput('Macro not found: $name', type: LineType.error);
      return CommandResult.error('Macro not found');
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('MACRO: ${macro.name}', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('Created:  ${_formatDate(macro.created)}');
    shellService.addOutput('Commands: ${macro.commands.length}');
    if (macro.description != null) {
      shellService.addOutput('Description: ${macro.description}');
    }
    shellService.addOutput('');
    shellService.addOutput('Commands:', type: LineType.info);
    
    for (var i = 0; i < macro.commands.length; i++) {
      shellService.addOutput('  ${i + 1}. ${macro.commands[i]}');
    }
    
    shellService.addOutput('═' * 50);
    
    return CommandResult.success('Macro displayed');
  }

  Future<CommandResult> _showStatus(ShellService shellService) async {
    if (macroService.isRecording) {
      shellService.addOutput('● RECORDING IN PROGRESS', type: LineType.success);
      shellService.addOutput('  Commands recorded: ${macroService.recordingCommandCount}');
      shellService.addOutput('  Stop: macro stop');
      shellService.addOutput('  Cancel: macro cancel');
    } else {
      shellService.addOutput('Status: Not recording', type: LineType.info);
      shellService.addOutput('Saved macros: ${macroService.macros.length}');
    }
    
    return CommandResult.success('Status displayed');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}