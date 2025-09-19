/// Pantalla principal de la aplicación
/// Maneja la interfaz de usuario y las interacciones principales

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/mod_manager.dart';
import '../models/mod.dart';
import '../models/version_history.dart';
import '../widgets/mod_card.dart';
import '../l10n/strings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  String t(String key) => AppStrings.texts[lang]![key]!;

  @override
  void initState() {
    super.initState();
    // La solicitud de permisos solo es necesaria en Android
    if (Platform.isAndroid) {
      _requestPermissions();
    }
    manager.init().then((_) => setState(() {}));
  }

  /// Se solicita permisos solo si es un dispositivo Android
  Future<void> _requestPermissions() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      print('Permisos de almacenamiento concedidos.');
    } else {
      print('Permisos de almacenamiento denegados.');
    }
  }

  /// Abre el canal de YouTube del creador
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

  /// Agrega un nuevo mod desde la URL ingresada
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(msgKey))));
    }
  }

  /// Elimina un mod de la lista de favoritos
  Future<void> _remove(String url) async {
    final ok = await manager.removeFavorite(url);
    if (ok) {
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('mod_deleted'))));
      }
    }
  }

  /// Alterna el estado de prioridad de un mod
  Future<void> _togglePriority(String url) async {
    await manager.togglePriority(url);
    setState(() {});
  }

  /// Actualiza todos los mods verificando nuevas versiones
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

    // Guarda los cambios después de actualizar
    await manager.save();
    
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

  /// Muestra diálogo con mods que fueron actualizados
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

    return Scaffold(
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
          // Campo para agregar nueva URL
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

          // Barra de búsqueda y filtros
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
          
          // Indicador de actualización en progreso
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

          // Lista de mods o mensaje vacío
          Expanded(
            child: filteredMods.isEmpty
                ? Center(
                    child: Text(
                      manager.favorites.isEmpty ? t('no_mods') : t('no_results'),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredMods.length,
                    itemBuilder: (context, index) {
                      final mod = filteredMods[index];
                      return ModCard(
                        mod: mod,
                        onTogglePriority: () => _togglePriority(mod.url),
                        onRemove: () => _remove(mod.url),
                        isRefreshing: refreshing,
                        translations: (key) => t(key),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}