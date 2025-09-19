/// Modelo de datos para representar un mod
/// Incluye serialización JSON y métodos de copia

import 'version_history.dart';

class Mod {
  final String title;
  final String version;
  final String description;
  final String url;
  final String downloadUrl;
  final String tags;
  final bool isPriority;
  final DateTime addedDate;
  final List<VersionHistory> versionHistory;

  Mod({
    required this.title,
    required this.version,
    required this.description,
    required this.url,
    required this.downloadUrl,
    required this.tags,
    this.isPriority = false,
    DateTime? addedDate,
    List<VersionHistory>? versionHistory,
  }) : addedDate = addedDate ?? DateTime(2024, 1, 1),
       versionHistory = versionHistory ?? const [];

  Map<String, dynamic> toJson() => {
        'title': title,
        'version': version,
        'description': description,
        'url': url,
        'download_url': downloadUrl,
        'tags': tags,
        'is_priority': isPriority,
        'added_date': addedDate.toIso8601String(),
        'version_history': versionHistory.map((v) => v.toJson()).toList(),
      };

  factory Mod.fromJson(Map<String, dynamic> json) => Mod(
        title: json['title'],
        version: json['version'],
        description: json['description'],
        url: json['url'],
        downloadUrl: json['download_url'],
        tags: json['tags'] ?? 'N/A',
        isPriority: json['is_priority'] ?? false,
        addedDate: json['added_date'] != null 
            ? DateTime.parse(json['added_date'])
            : DateTime.now(),
        versionHistory: (json['version_history'] as List?)
            ?.map((v) => VersionHistory.fromJson(v))
            .toList() ?? [],
      );

  Mod copyWith({
    String? title,
    String? version,
    String? description,
    String? url,
    String? downloadUrl,
    String? tags,
    bool? isPriority,
    DateTime? addedDate,
    List<VersionHistory>? versionHistory,
  }) => Mod(
    title: title ?? this.title,
    version: version ?? this.version,
    description: description ?? this.description,
    url: url ?? this.url,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    tags: tags ?? this.tags,
    isPriority: isPriority ?? this.isPriority,
    addedDate: addedDate ?? this.addedDate,
    versionHistory: versionHistory ?? this.versionHistory,
  );
}