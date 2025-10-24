import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/ssh_connection.dart';

class SSHService extends ChangeNotifier {
  final List<SSHConnection> _connections = [];
  SSHConnection? _activeConnection;

  List<SSHConnection> get connections => List.unmodifiable(_connections);
  SSHConnection? get activeConnection => _activeConnection;
  bool get isConnected => _activeConnection != null;

  SSHService() {
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final connectionsJson = prefs.getStringList('ssh_connections') ?? [];
    
    _connections.clear();
    _connections.addAll(
      connectionsJson.map((json) => SSHConnection.fromJson(jsonDecode(json)))
    );
    
    notifyListeners();
  }

  Future<void> _saveConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final connectionsJson = _connections
        .map((conn) => jsonEncode(conn.toJson()))
        .toList();
    await prefs.setStringList('ssh_connections', connectionsJson);
  }

  Future<void> addConnection(SSHConnection connection) async {
    _connections.add(connection);
    await _saveConnections();
    notifyListeners();
  }

  Future<void> removeConnection(String id) async {
    _connections.removeWhere((conn) => conn.id == id);
    if (_activeConnection?.id == id) {
      _activeConnection = null;
    }
    await _saveConnections();
    notifyListeners();
  }

  Future<bool> connect(String id) async {
    final connection = _connections.firstWhere((conn) => conn.id == id);
    
    try {
      // In production, implement actual SSH connection using dartssh2 package
      // For now, simulate connection
      await Future.delayed(const Duration(seconds: 2));
      
      _activeConnection = connection;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SSH connection error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    _activeConnection = null;
    notifyListeners();
  }

  Future<String> executeCommand(String command) async {
    if (_activeConnection == null) {
      return 'Error: Not connected to any server';
    }

    try {
      // In production, execute actual SSH command
      // For now, simulate command execution
      await Future.delayed(const Duration(milliseconds: 500));
      return 'Command executed on ${_activeConnection!.host}:\n$command\n[Simulated output]';
    } catch (e) {
      return 'Error executing command: $e';
    }
  }
}