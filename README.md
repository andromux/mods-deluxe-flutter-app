# deluxemanager

# Guía rápida (comandos) — crear AppImage desde `build/linux/x64/release/bundle/`

Copia y pega estos comandos desde la raíz de tu proyecto (`~/aplicaciones_flutter/deluxemanager`). Son un **cheat-sheet** paso a paso:

```bash
# 0) Moverse al proyecto
cd ~/aplicaciones_flutter/deluxemanager

# 1) (opcional si ya lo hiciste) Compilar release
flutter build linux --release

# 2) Definir nombre AppDir y crear estructura
APP=deluxemanager.AppDir
mkdir -p "$APP"/usr/bin

# 3) Copiar bundle de Flutter al AppDir
cp -r build/linux/x64/release/bundle/* "$APP"/usr/bin/

# 4) Crear AppRun (lanzador)
cat > "$APP"/AppRun <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/deluxemanager" "$@"
EOF
chmod +x "$APP"/AppRun

# 5) Crear archivo .desktop (ajusta Name/Comment si quieres)
cat > "$APP"/deluxemanager.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Deluxe Manager
Exec=deluxemanager
Icon=deluxemanager
Categories=Utility;
EOF
chmod 644 "$APP"/deluxemanager.desktop

# 6) Añadir icono (reemplaza path/to/icon.png)
# - copia también a usr/share/icons para mayor compatibilidad
mkdir -p "$APP"/usr/share/icons/hicolor/256x256/apps
cp path/to/icon.png "$APP"/deluxemanager.png
cp path/to/icon.png "$APP"/usr/share/icons/hicolor/256x256/apps/deluxemanager.png

# 7) Asegurarse de que el binario sea ejecutable
chmod +x "$APP"/usr/bin/deluxemanager

# 8) Instalar appimagetool (intenta apt; si no está, descarga desde GitHub Releases)
sudo apt update
sudo apt install appimagetool
# Si no lo tienes en repos: descarga manual desde https://github.com/AppImage/AppImageKit/releases
# y pon el binario en /usr/local/bin/appimagetool con permisos ejecutables.

# 9) Construir AppImage
appimagetool "$APP"

# 10) Hacer ejecutable y probar el AppImage generado
chmod +x *.AppImage
./$(ls *.AppImage | head -n1)

# 11) (opcional) limpiar AppDir
rm -rf "$APP"
```

**Notas/Consejos rápidos**

* El `.desktop` debe llamarse exactamente `deluxemanager.desktop` y estar en la raíz del AppDir (junto a `AppRun`).
* `Icon=deluxemanager` busca `deluxemanager.png` en la raíz o en `usr/share/icons/...`.
* Si quieres reducir tamaño: puedes `strip -s "$APP"/usr/bin/deluxemanager` **(haz backup primero)**.
* Si quieres versionar el AppImage, renómbralo después de crear:
  `mv *.AppImage DeluxeManager-1.0-x86_64.AppImage`

generar AppImage
appimagetool deluxemanager.AppDir

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
