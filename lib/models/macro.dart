class Macro {
  final String id;
  final String name;
  final List<String> commands;
  final DateTime created;
  final String? description;

  Macro({
    required this.id,
    required this.name,
    required this.commands,
    DateTime? created,
    this.description,
  }) : created = created ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'commands': commands,
    'created': created.toIso8601String(),
    'description': description,
  };

  factory Macro.fromJson(Map<String, dynamic> json) => Macro(
    id: json['id'],
    name: json['name'],
    commands: List<String>.from(json['commands']),
    created: DateTime.parse(json['created']),
    description: json['description'],
  );
}