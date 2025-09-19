/// Modelo para representar el historial de versiones de un mod
/// Incluye serialización JSON para persistencia

class VersionHistory {
  final String version;
  final DateTime date;
  final String description;

  VersionHistory({
    required this.version,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'date': date.toIso8601String(),
    'description': description,
  };

  factory VersionHistory.fromJson(Map<String, dynamic> json) => VersionHistory(
    version: json['version'],
    date: DateTime.parse(json['date']),
    description: json['description'] ?? '',
  );
}