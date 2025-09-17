import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const ModManagerApp());

class Mod {
  final String title;
  final String version;
  final String description;
  final String url;
  final String downloadUrl;
  final String tags;

  const Mod({
    required this.title,
    required this.version,
    required this.description,
    required this.url,
    required this.downloadUrl,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'version': version,
        'description': description,
        'url': url,
        'download_url': downloadUrl,
        'tags': tags,
      };

  factory Mod.fromJson(Map<String, dynamic> json) => Mod(
        title: json['title'],
        version: json['version'],
        description: json['description'],
        url: json['url'],
        downloadUrl: json['download_url'],
        tags: json['tags'] ?? 'N/A',
      );
}

class ModManager {
  late final File _dataFile;
  List<Mod> favorites = [];

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    final appDir = Directory('${dir.path}/sm64_mod_manager');
    await appDir.create(recursive: true);
    _dataFile = File('${appDir.path}/favorites.json');
    if (await _dataFile.exists()) {
      final raw = await _dataFile.readAsString();
      if (raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        favorites = list.map((e) => Mod.fromJson(e)).toList();
      }
    }
  }

  Future<void> _save() async {
    final data = jsonEncode(favorites.map((e) => e.toJson()).toList());
    await _dataFile.writeAsString(data);
  }

  Future<String?> addFavorite(String url) async {
    if (!url.startsWith('http')) return 'invalid_url';
    if (favorites.any((m) => m.url == url)) return 'mod_exists';

    final mod = await _scrape(url);
    if (mod == null) return 'mod_error';
    favorites.add(mod);
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

      final desc = doc
              .querySelector('div.bbWrapper')
              ?.text
              .replaceAll(RegExp(r'\s+'), ' ')
              .substring(0, 200) ??
          'N/A';

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
  String lang = 'es';
  bool loading = false;

  final texts = {
    'es': {
      'title': 'SM64 Mod Manager',
      'url_hint': 'Pega la URL del mod…',
      'add': 'Agregar',
      'view': 'Ver en la Web',
      'download': 'Descargar',
      'delete': 'Eliminar',
      'no_mods': 'No hay mods favoritos',
      'processing': 'Procesando…',
      'invalid_url': 'URL inválida',
      'mod_exists': 'El mod ya existe',
      'mod_added': '¡Mod agregado!',
      'mod_error': 'Error al agregar mod',
      'mod_deleted': 'Mod eliminado',
    },
    'en': {
      'title': 'SM64 Mod Manager',
      'url_hint': 'Paste mod URL…',
      'add': 'Add',
      'view': 'View Web',
      'download': 'Download',
      'delete': 'Delete',
      'no_mods': 'No favorite mods',
      'processing': 'Processing…',
      'invalid_url': 'Invalid URL',
      'mod_exists': 'Mod already exists',
      'mod_added': 'Mod added!',
      'mod_error': 'Error adding mod',
      'mod_deleted': 'Mod deleted',
    }
  };

  String t(String key) => texts[lang]![key]!;

  @override
  void initState() {
    super.initState();
    manager.init().then((_) => setState(() {}));
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(t('title')),
          actions: [
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
                    onPressed: loading ? null : _addMod,
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
            Expanded(
              child: manager.favorites.isEmpty
                  ? Center(child: Text(t('no_mods')))
                  : ListView.builder(
                      itemCount: manager.favorites.length,
                      itemBuilder: (c, i) {
                        final m = manager.favorites[i];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        child: Text(m.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold))),
                                    Text('v${m.version}',
                                        style: const TextStyle(
                                            fontStyle: FontStyle.italic)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Tags: ${m.tags}',
                                    style:
                                        const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(m.description),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                        onPressed: () => launchUrl(Uri.parse(m.url)),
                                        child: Text(t('view'))),
                                    TextButton(
                                        onPressed: () => launchUrl(Uri.parse(m.downloadUrl)),
                                        child: Text(t('download'))),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _remove(m.url),
                                    )
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
