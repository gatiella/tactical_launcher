import 'base_command.dart';
import '../services/shell_service.dart';
import '../services/app_manager_service.dart';
import '../services/ssh_service.dart';
import '../models/command_result.dart';
import '../models/terminal_line.dart';
import '../models/ssh_connection.dart';

class SSHCommand extends BaseCommand {
  final SSHService sshService;

  SSHCommand(this.sshService);

  @override
  String get name => 'ssh';

  @override
  String get description => 'Manage SSH connections';

  @override
  String get usage => 'ssh <connect|disconnect|list|add|remove> [args]';

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
      case 'list':
        return await _listConnections(shellService);
      
      case 'add':
        if (args.length < 4) {
          shellService.addOutput('Usage: ssh add <name> <host> <username>', type: LineType.error);
          return CommandResult.error('Invalid arguments');
        }
        return await _addConnection(args[1], args[2], args[3], shellService);
      
      case 'connect':
        if (args.length < 2) {
          shellService.addOutput('Usage: ssh connect <id|name>', type: LineType.error);
          return CommandResult.error('No connection specified');
        }
        return await _connect(args[1], shellService);
      
      case 'disconnect':
        return await _disconnect(shellService);
      
      case 'remove':
        if (args.length < 2) {
          shellService.addOutput('Usage: ssh remove <id>', type: LineType.error);
          return CommandResult.error('No connection specified');
        }
        return await _removeConnection(args[1], shellService);
      
      case 'status':
        return await _showStatus(shellService);
      
      default:
        shellService.addOutput('Unknown action: $action', type: LineType.error);
        printHelp(shellService);
        return CommandResult.error('Unknown action');
    }
  }

  Future<CommandResult> _listConnections(ShellService shellService) async {
    final connections = sshService.connections;
    
    if (connections.isEmpty) {
      shellService.addOutput('No SSH connections saved', type: LineType.info);
      shellService.addOutput('Add connection: ssh add <name> <host> <user>');
      return CommandResult.success('No connections');
    }

    shellService.addOutput('═' * 50);
    shellService.addOutput('SSH CONNECTIONS', type: LineType.info);
    shellService.addOutput('═' * 50);

    for (var i = 0; i < connections.length; i++) {
      final conn = connections[i];
      final isActive = sshService.activeConnection?.id == conn.id;
      
      shellService.addOutput('[$i] ${conn.name}${isActive ? " (ACTIVE)" : ""}');
      shellService.addOutput('    ${conn.username}@${conn.host}:${conn.port}', type: LineType.info);
    }

    shellService.addOutput('═' * 50);
    return CommandResult.success('Listed ${connections.length} connections');
  }

  Future<CommandResult> _addConnection(
    String name,
    String host,
    String username,
    ShellService shellService,
  ) async {
    final connection = SSHConnection(
      id: 'ssh_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      host: host,
      username: username,
    );

    await sshService.addConnection(connection);
    
    shellService.addOutput('✓ SSH connection added: $name', type: LineType.success);
    shellService.addOutput('  Connect with: ssh connect $name');
    
    return CommandResult.success('Connection added');
  }

  Future<CommandResult> _connect(String identifier, ShellService shellService) async {
    final connections = sshService.connections;
    SSHConnection? connection;

    // Try to find by index
    final index = int.tryParse(identifier);
    if (index != null && index >= 0 && index < connections.length) {
      connection = connections[index];
    } else {
      // Try to find by name
      try {
        connection = connections.firstWhere((c) => c.name == identifier);
      } catch (e) {
        shellService.addOutput('Connection not found: $identifier', type: LineType.error);
        return CommandResult.error('Connection not found');
      }
    }

    shellService.addOutput('Connecting to ${connection.host}...');
    
    final success = await sshService.connect(connection.id);
    
    if (success) {
      shellService.addOutput('✓ Connected to ${connection.name}', type: LineType.success);
      shellService.addOutput('  ${connection.username}@${connection.host}');
      return CommandResult.success('Connected');
    } else {
      shellService.addOutput('✗ Connection failed', type: LineType.error);
      return CommandResult.error('Connection failed');
    }
  }

  Future<CommandResult> _disconnect(ShellService shellService) async {
    if (!sshService.isConnected) {
      shellService.addOutput('Not connected to any server', type: LineType.warning);
      return CommandResult.error('Not connected');
    }

    final connName = sshService.activeConnection!.name;
    await sshService.disconnect();
    
    shellService.addOutput('✓ Disconnected from $connName', type: LineType.success);
    return CommandResult.success('Disconnected');
  }

  Future<CommandResult> _removeConnection(String id, ShellService shellService) async {
    await sshService.removeConnection(id);
    shellService.addOutput('✓ Connection removed', type: LineType.success);
    return CommandResult.success('Connection removed');
  }

  Future<CommandResult> _showStatus(ShellService shellService) async {
    if (!sshService.isConnected) {
      shellService.addOutput('Status: Disconnected', type: LineType.info);
      return CommandResult.success('Disconnected');
    }

    final conn = sshService.activeConnection!;
    shellService.addOutput('═' * 50);
    shellService.addOutput('SSH STATUS', type: LineType.info);
    shellService.addOutput('═' * 50);
    shellService.addOutput('Status:      CONNECTED', type: LineType.success);
    shellService.addOutput('Connection:  ${conn.name}');
    shellService.addOutput('Host:        ${conn.host}:${conn.port}');
    shellService.addOutput('Username:    ${conn.username}');
    shellService.addOutput('═' * 50);
    
    return CommandResult.success('Status displayed');
  }
}