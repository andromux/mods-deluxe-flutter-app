# deluxemanager

SM64 Mod Manager – Guía para Developers
1. Descripción del proyecto

SM64 Mod Manager es una aplicación Flutter que permite:

Guardar mods favoritos de una página web.

Extraer información básica de cada mod: título, versión, descripción, tags, URL y enlace de descarga.

Guardar localmente la lista de mods en un archivo JSON (favorites.json).

Abrir el mod en la web o descargarlo.

Eliminar mods de la lista.

El proyecto está pensado para Android, iOS y Desktop (Windows/Linux/macOS).

2. Estructura principal
Archivos principales

main.dart: Contiene toda la lógica de la app (UI y backend).

Dependencias externas usadas:

http: Para hacer requests HTTP.

html: Para parsear contenido HTML.

path_provider: Para obtener rutas de almacenamiento seguro.

url_launcher: Para abrir URLs en navegador.

flutter/material.dart: Para UI básica.

Clases principales

Mod

Modelo que representa un mod.

Propiedades:

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
