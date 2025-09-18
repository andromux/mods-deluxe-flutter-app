import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:external_path/external_path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const ModManagerApp());

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

class ModManager {
  late final File _dataFile;
  List<Mod> favorites = [];

  Future<void> init() async {
    String basePath;
    if (Platform.isAndroid) {
      // Usa external_path para almacenamiento externo en Android
      basePath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOCUMENTS);
    } else {
      // Usa path_provider para el directorio de documentos en otras plataformas
      final dir = await getApplicationDocumentsDirectory();
      basePath = dir.path;
    }

    final appDir = Directory('$basePath/deluxe-manager');
    
    await appDir.create(recursive: true);

    _dataFile = File('${appDir.path}/favorites.json');

    if (await _dataFile.exists()) {
      try {
        final raw = await _dataFile.readAsString();
        if (raw.isNotEmpty) {
          final list = jsonDecode(raw) as List;
          favorites = list.map((e) => Mod.fromJson(e)).toList();
        }
      } catch (e) {
        print("Error leyendo favorites.json: $e");
        await _dataFile.writeAsString('[]');
      }
    } else {
      await _dataFile.writeAsString('[]');
    }
  }

  Future<void> _save() async {
    try {
      final data = jsonEncode(favorites.map((e) => e.toJson()).toList());
      await _dataFile.writeAsString(data);
    } catch (e) {
      print("Error guardando favorites.json: $e");
    }
  }

  Future<String?> addFavorite(String url) async {
    if (!url.startsWith('http')) return 'invalid_url';
    if (favorites.any((m) => m.url == url)) return 'mod_exists';

    final mod = await _scrape(url);
    if (mod == null) return 'mod_error';
    
    final modWithHistory = mod.copyWith(
      addedDate: DateTime.now(),
      versionHistory: [
        VersionHistory(
          version: mod.version,
          date: DateTime.now(),
          description: mod.description,
        )
      ],
    );
    
    favorites.add(modWithHistory);
    await _save();
    return 'mod_added';
  }

  Future<bool> removeFavorite(String url) async {
    final before = favorites.length;
    favorites.removeWhere((m) => m.url == url);
    if (favorites.length < before) {
      await _save();
      return true;
    }
    return false;
  }

  Future<void> togglePriority(String url) async {
    final index = favorites.indexWhere((m) => m.url == url);
    if (index >= 0) {
      favorites[index] = favorites[index].copyWith(
        isPriority: !favorites[index].isPriority,
      );
      await _save();
    }
  }

  List<Mod> getFilteredMods(String searchQuery, String sortBy) {
    var filtered = favorites.where((mod) {
      final query = searchQuery.toLowerCase();
      return mod.title.toLowerCase().contains(query) ||
             mod.tags.toLowerCase().contains(query) ||
             mod.version.toLowerCase().contains(query);
    }).toList();

    switch (sortBy) {
      case 'name':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'version':
        filtered.sort((a, b) => a.version.compareTo(b.version));
        break;
      case 'date':
        filtered.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
      case 'priority':
        filtered.sort((a, b) {
          if (a.isPriority && !b.isPriority) return -1;
          if (!a.isPriority && b.isPriority) return 1;
          return a.title.compareTo(b.title);
        });
        break;
    }

    return filtered;
  }

  Future<Mod?> scrapeMod(String url) async {
    return await _scrape(url);
  }

  Future<Mod?> _scrape(String url) async {
    try {
      final resp = await http.get(Uri.parse(url));
      final doc = html.parse(resp.body);

      final titleTag = doc.querySelector('h1.p-title-value');
      final title = titleTag?.text.trim().split('(').first.trim() ?? 'N/A';
      final version = titleTag
              ?.querySelector('span.u-muted')
              ?.text
              .replaceAll(RegExp(r'[()v]'), '') ??
          'N/A';

      final descElement = doc.querySelector('div.bbWrapper');
      String desc = 'N/A';
      
      if (descElement != null) {
        descElement.querySelectorAll('img').forEach((img) => img.remove());
        
        desc = descElement.text
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        
        if (desc.length > 200) {
          desc = '${desc.substring(0, 200)}...';
        }
        
        if (desc.isEmpty) desc = 'N/A';
      }

      final downloadTag =
          doc.querySelector('a[href*="download"]')?.attributes['href'];
      final downloadUrl =
          downloadTag != null ? Uri.parse(url).resolve(downloadTag).toString() : url;

      final tags = doc
              .querySelectorAll('dl.tagList a.tagItem')
              .map((e) => e.text.trim())
              .join(', ') ??
          'N/A';

      return Mod(
        title: title,
        version: version,
        description: desc,
        url: url,
        downloadUrl: downloadUrl,
        tags: tags.isEmpty ? 'N/A' : tags,
      );
    } catch (_) {
      return null;
    }
  }
}

class ModManagerApp extends StatefulWidget {
  const ModManagerApp({super.key});
  @override
  State<ModManagerApp> createState() => _ModManagerAppState();
}

class _ModManagerAppState extends State<ModManagerApp> {
  final ModManager manager = ModManager();
  final TextEditingController urlCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();
  String lang = 'es';
  bool loading = false;
  bool refreshing = false;
  String refreshStatus = '';
  String searchQuery = '';
  String sortBy = 'priority';
  List<String> updatedModNames = [];

  final texts = {
    'es': {
      'title': 'SM64 Mod Manager',
      'url_hint': 'Pega la URL del mod…',
      'search_hint': 'Buscar mods…',
      'add': 'Agregar',
      'view': 'Ver en la Web',
      'download': 'Descargar',
      'delete': 'Eliminar',
      'refresh': 'Actualizar Mods',
      'no_mods': 'No hay mods favoritos',
      'no_results': 'No hay resultados para tu búsqueda',
      'processing': 'Procesando…',
      'invalid_url': 'URL inválida',
      'mod_exists': 'El mod ya existe',
      'mod_added': '¡Mod agregado!',
      'mod_error': 'Error al agregar mod',
      'mod_deleted': 'Mod eliminado',
      'refreshing': 'Actualizando mods…',
      'refresh_complete': 'Actualización completada',
      'mods_updated': 'mods actualizados',
      'checking_mod': 'Verificando mod',
      'of': 'de',
      'sort_by': 'Ordenar por',
      'priority': 'Prioridad',
      'name': 'Nombre',
      'version': 'Versión',
      'date': 'Fecha',
      'priority_mod': 'Mod prioritario',
      'updated_mods_title': 'Mods Actualizados',
      'updated_mods_detail': 'Los siguientes mods tienen nuevas versiones:',
      'close': 'Cerrar',
      'added_on': 'Agregado el',
      'creator_credit': 'por retired64',
    },
    'en': {
      'title': 'SM64 Mod Manager',
      'url_hint': 'Paste mod URL…',
      'search_hint': 'Search mods…',
      'add': 'Add',
      'view': 'View Web',
      'download': 'Download',
      'delete': 'Delete',
      'refresh': 'Update Mods',
      'no_mods': 'No favorite mods',
      'no_results': 'No results for your search',
      'processing': 'Processing…',
      'invalid_url': 'Invalid URL',
      'mod_exists': 'Mod already exists',
      'mod_added': 'Mod added!',
      'mod_error': 'Error adding mod',
      'mod_deleted': 'Mod deleted',
      'refreshing': 'Updating mods…',
      'refresh_complete': 'Update completed',
      'mods_updated': 'mods updated',
      'checking_mod': 'Checking mod',
      'of': 'of',
      'sort_by': 'Sort by',
      'priority': 'Priority',
      'name': 'Name',
      'version': 'Version',
      'date': 'Date',
      'priority_mod': 'Priority mod',
      'updated_mods_title': 'Updated Mods',
      'updated_mods_detail': 'The following mods have new versions:',
      'close': 'Close',
      'added_on': 'Added on',
      'creator_credit': 'by retired64',
    }
  };

  String t(String key) => texts[lang]![key]!;

  @override
  void initState() {
    super.initState();
    // La solicitud de permisos solo es necesaria en Android
    if (Platform.isAndroid) {
      _requestPermissions();
    }
    manager.init().then((_) => setState(() {}));
  }

  // Se solicita permisos solo si es un dispositivo Android
  Future<void> _requestPermissions() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      print('Permisos de almacenamiento concedidos.');
    } else {
      print('Permisos de almacenamiento denegados.');
    }
  }

  Future<void> _openCreatorChannel() async {
    const youtubeUrl = 'https://www.youtube.com/@retired64';
    try {
      await launchUrl(Uri.parse(youtubeUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al abrir el canal')),
        );
      }
    }
  }

  Future<void> _addMod() async {
    final url = urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() => loading = true);
    final msgKey = await manager.addFavorite(url);
    setState(() {
      loading = false;
      urlCtrl.clear();
    });
    if (msgKey != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t(msgKey))));
    }
  }

  Future<void> _remove(String url) async {
    final ok = await manager.removeFavorite(url);
    if (ok && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('mod_deleted'))));
    }
  }

  Future<void> _togglePriority(String url) async {
    await manager.togglePriority(url);
    setState(() {});
  }

  Future<void> _refreshMods() async {
    if (manager.favorites.isEmpty) return;
    
    setState(() {
      refreshing = true;
      refreshStatus = '';
      updatedModNames.clear();
    });

    int updatedCount = 0;
    final totalMods = manager.favorites.length;

    for (int i = 0; i < manager.favorites.length; i++) {
      final oldMod = manager.favorites[i];
      
      setState(() {
        refreshStatus = '${t('checking_mod')} ${i + 1} ${t('of')} $totalMods';
      });

      try {
        final updatedMod = await manager.scrapeMod(oldMod.url);

        if (updatedMod != null && updatedMod.version != oldMod.version) {
          final newHistory = List<VersionHistory>.from(oldMod.versionHistory);
          newHistory.add(VersionHistory(
            version: updatedMod.version,
            date: DateTime.now(),
            description: updatedMod.description,
          ));

          manager.favorites[i] = updatedMod.copyWith(
            isPriority: oldMod.isPriority,
            addedDate: oldMod.addedDate,
            versionHistory: newHistory,
          );
          
          updatedCount++;
          updatedModNames.add('${oldMod.title} (${oldMod.version} → ${updatedMod.version})');
        }
      } catch (e) {
        print('Error actualizando mod ${oldMod.title}: $e');
      }

      if (i < manager.favorites.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    await manager._save();
    
    setState(() {
      refreshing = false;
      refreshStatus = '';
    });

    if (mounted && updatedCount > 0) {
      _showUpdatedModsDialog(updatedCount);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('refresh_complete')}: 0 ${t('mods_updated')}')),
      );
    }
  }

  void _showUpdatedModsDialog(int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('updated_mods_title')),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t('refresh_complete')}: $count ${t('mods_updated')}'),
              const SizedBox(height: 16),
              if (updatedModNames.isNotEmpty) ...[
                Text(t('updated_mods_detail')),
                const SizedBox(height: 8),
                ...updatedModNames.map((name) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $name', style: const TextStyle(fontSize: 12)),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMods = manager.getFilteredMods(searchQuery, sortBy);

    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(t('title')),
              GestureDetector(
                onTap: _openCreatorChannel,
                child: Text(
                  t('creator_credit'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: refreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
              onPressed: (loading || refreshing) ? null : _refreshMods,
              tooltip: t('refresh'),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: lang,
              underline: const SizedBox(),
              dropdownColor: Colors.grey[900],
              items: const [
                DropdownMenuItem(value: 'es', child: Text('ES')),
                DropdownMenuItem(value: 'en', child: Text('EN')),
              ],
              onChanged: (v) => setState(() => lang = v!),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: urlCtrl,
                      decoration: InputDecoration(
                        hintText: t('url_hint'),
                        filled: true,
                        fillColor: Colors.grey[850],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (loading || refreshing) ? null : _addMod,
                    child: loading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t('add')),
                  )
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: t('search_hint'),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[850],
                        isDense: true,
                      ),
                      onChanged: (value) => setState(() => searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: sortBy,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: 'priority', child: Text(t('priority'))),
                        DropdownMenuItem(value: 'name', child: Text(t('name'))),
                        DropdownMenuItem(value: 'version', child: Text(t('version'))),
                        DropdownMenuItem(value: 'date', child: Text(t('date'))),
                      ],
                      onChanged: (v) => setState(() => sortBy = v!),
                    ),
                  ),
                ],
              ),
            ),
            
            if (refreshing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withOpacity(0.1),
                child: Column(
                  children: [
                    Text(t('refreshing'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (refreshStatus.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(refreshStatus, style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),

            Expanded(
              child: filteredMods.isEmpty
                  ? Center(
                      child: Text(
                        manager.favorites.isEmpty ? t('no_mods') : t('no_results'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredMods.length,
                      itemBuilder: (c, i) {
                        final m = filteredMods[i];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          color: m.isPriority ? Colors.amber.withOpacity(0.1) : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (m.isPriority)
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                    if (m.isPriority) const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        m.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      'v${m.version}',
                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tags: ${m.tags}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  '${t('added_on')}: ${m.addedDate.day}/${m.addedDate.month}/${m.addedDate.year}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Text(m.description),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        m.isPriority ? Icons.star : Icons.star_border,
                                        color: m.isPriority ? Colors.amber : Colors.grey,
                                      ),
                                      onPressed: () => _togglePriority(m.url),
                                      tooltip: t('priority_mod'),
                                    ),
                                    TextButton(
                                      onPressed: () => launchUrl(Uri.parse(m.url)),
                                      child: Text(t('view')),
                                    ),
                                    TextButton(
                                      onPressed: () => launchUrl(Uri.parse(m.downloadUrl)),
                                      child: Text(t('download')),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: (refreshing) ? null : () => _remove(m.url),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}