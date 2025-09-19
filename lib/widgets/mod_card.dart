/// Widget personalizado para mostrar la información de cada mod
/// Incluye botones para acciones como prioridad, ver, descargar y eliminar

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mod.dart';

class ModCard extends StatelessWidget {
  final Mod mod;
  final VoidCallback onTogglePriority;
  final VoidCallback onRemove;
  final bool isRefreshing;
  final String Function(String) translations;

  const ModCard({
    super.key,
    required this.mod,
    required this.onTogglePriority,
    required this.onRemove,
    required this.isRefreshing,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: mod.isPriority ? Colors.amber.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y versión
            Row(
              children: [
                if (mod.isPriority)
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                if (mod.isPriority) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mod.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'v${mod.version}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Tags
            Text(
              'Tags: ${mod.tags}',
              style: const TextStyle(color: Colors.grey),
            ),
            
            // Fecha de agregado
            Text(
              '${translations('added_on')}: ${mod.addedDate.day}/${mod.addedDate.month}/${mod.addedDate.year}',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 4),
            
            // Descripción
            Text(mod.description),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón de prioridad
                IconButton(
                  icon: Icon(
                    mod.isPriority ? Icons.star : Icons.star_border,
                    color: mod.isPriority ? Colors.amber : Colors.grey,
                  ),
                  onPressed: onTogglePriority,
                  tooltip: translations('priority_mod'),
                ),
                
                // Botón para ver en web
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(mod.url)),
                  child: Text(translations('view')),
                ),
                
                // Botón para descargar
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(mod.downloadUrl)),
                  child: Text(translations('download')),
                ),
                
                // Botón para eliminar
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: isRefreshing ? null : onRemove,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}