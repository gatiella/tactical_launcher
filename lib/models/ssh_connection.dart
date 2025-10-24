class SSHConnection {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? privateKey;
  final DateTime lastConnected;

  SSHConnection({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    this.password,
    this.privateKey,
    DateTime? lastConnected,
  }) : lastConnected = lastConnected ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'username': username,
    'password': password,
    'privateKey': privateKey,
    'lastConnected': lastConnected.toIso8601String(),
  };

  factory SSHConnection.fromJson(Map<String, dynamic> json) => SSHConnection(
    id: json['id'],
    name: json['name'],
    host: json['host'],
    port: json['port'] ?? 22,
    username: json['username'],
    password: json['password'],
    privateKey: json['privateKey'],
    lastConnected: DateTime.parse(json['lastConnected']),
  );
}