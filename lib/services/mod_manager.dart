/// Servicio principal para gestionar mods
/// Maneja scraping web, almacenamiento local y operaciones CRUD

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:external_path/external_path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/mod.dart';
import '../models/version_history.dart';

class ModManager {
  late final File _dataFile;
  List<Mod> favorites = [];

  /// Inicializa el manager y carga datos persistidos
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

  /// Guarda la lista de favoritos en archivo JSON (método público)
  Future<void> save() async {
    try {
      final data = jsonEncode(favorites.map((e) => e.toJson()).toList());
      await _dataFile.writeAsString(data);
    } catch (e) {
      print("Error guardando favorites.json: $e");
    }
  }

  /// Método privado interno para guardar
  Future<void> _save() async {
    await save();
  }

  /// Agrega un mod a favoritos desde una URL
  /// Retorna clave de mensaje para mostrar resultado
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

  /// Elimina un mod de favoritos por URL
  Future<bool> removeFavorite(String url) async {
    final before = favorites.length;
    favorites.removeWhere((m) => m.url == url);
    if (favorites.length < before) {
      await _save();
      return true;
    }
    return false;
  }

  /// Alterna el estado de prioridad de un mod
  Future<void> togglePriority(String url) async {
    final index = favorites.indexWhere((m) => m.url == url);
    if (index >= 0) {
      favorites[index] = favorites[index].copyWith(
        isPriority: !favorites[index].isPriority,
      );
      await _save();
    }
  }

  /// Filtra y ordena mods según criterios de búsqueda
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

  /// Scrappea información de un mod desde una URL pública
  Future<Mod?> scrapeMod(String url) async {
    return await _scrape(url);
  }

  /// Método privado que realiza el scraping web
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