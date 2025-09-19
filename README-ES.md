# Documentación del Proyecto Flutter - SM64 Mod Manager

- [Chat de Inteligencia Artificial de este proyecto](https://deepwiki.com/andromux/mods-deluxe-flutter-app)

<div align="center">

  <h3>¿Te gusta este proyecto?</h3>
  <p>Regalame una estrella o haz un fork si te gustaría contribuir!</p>

  <a href="https://github.com/andromux/mods-deluxe-flutter-app/stargazers">
    <img src="https://img.shields.io/github/stars/andromux/mods-deluxe-flutter-app?style=social" alt="GitHub Stars mods-deluxe-flutter-app"/>
  </a>

  <a href="https://github.com/andromux/mods-deluxe-flutter-app/fork">
    <img src="https://img.shields.io/github/forks/andromux/mods-deluxe-flutter-app?style=social" alt="GitHub Forks mods-deluxe-flutter-app"/>
  </a>

</div>

## Arquitectura General

Este proyecto está organizado siguiendo el patrón de **arquitectura por capas** que separa claramente las responsabilidades:
- **Presentación** (UI/Widgets)
- **Lógica de Negocio** (Services) 
- **Datos** (Models)
- **Configuración** (App/Main)
- **Recursos** (Localización)

Esta estructura facilita el mantenimiento, testing, escalabilidad y colaboración en equipo.

---

## Archivos Raíz

### **main.dart**
**Responsabilidad**: Punto de entrada único y minimalista de la aplicación.
- **Qué hace**: Ejecuta la función `main()` que inicializa `ModManagerApp` 
- **Por qué es importante**: Mantiene el arranque simple y delega toda la configuración a `app.dart`
- **Relaciones**: Importa y ejecuta `ModManagerApp` desde `app.dart`
- **Beneficio para escalabilidad**: Al ser minimalista, permite cambios en la configuración sin tocar el entry point

### **app.dart** 
**Responsabilidad**: Configuración central de la aplicación Flutter.
- **Qué hace**: Define el `MaterialApp` con tema oscuro, título y ruta inicial hacia `HomePage`
- **Por qué es importante**: Centraliza configuraciones globales (tema, rutas, localización futura)
- **Relaciones**: Importa `HomePage` y la establece como pantalla inicial
- **Beneficio para escalabilidad**: Facilita agregar nuevas rutas, temas o configuraciones globales sin impactar otros archivos

---

## Carpeta `models/`

### **mod.dart**
**Responsabilidad**: Modelo de datos principal que representa un mod de SM64.
- **Qué hace**: Define la estructura `Mod` con propiedades como título, versión, descripción, URL, etc.
- **Funcionalidades clave**:
  - Serialización JSON (`toJson()`, `fromJson()`) para persistencia
  - Método `copyWith()` para crear copias inmutables
  - Validación y valores por defecto
- **Por qué es importante**: Es el corazón de datos de la aplicación - todo gira en torno a los mods
- **Relaciones**: Usado por `ModManager`, `HomePage`, `ModCard` y referencia `VersionHistory`
- **Beneficio para escalabilidad**: Centraliza la estructura de datos, facilitando cambios de schema y validaciones

### **version_history.dart**
**Responsabilidad**: Modelo para el historial de versiones de cada mod.
- **Qué hace**: Estructura simple con versión, fecha y descripción de cambios
- **Funcionalidades clave**: Serialización JSON para guardar el historial completo
- **Por qué es importante**: Permite rastrear actualizaciones y cambios en mods a lo largo del tiempo
- **Relaciones**: Usado dentro del modelo `Mod` como lista de historial
- **Beneficio para escalabilidad**: Permite agregar campos adicionales al historial sin romper funcionalidad existente

---

## Carpeta `services/`

### **mod_manager.dart**
**Responsabilidad**: Lógica de negocio central y capa de servicios de la aplicación.
- **Qué hace**: 
  - **Gestión de almacenamiento**: Maneja archivos JSON en storage local/externo
  - **Web scraping**: Extrae información de mods desde URLs usando `html` parser
  - **CRUD operations**: Agregar, eliminar, actualizar favoritos
  - **Filtrado y ordenamiento**: Búsquedas y clasificación de mods
  - **Gestión de permisos**: Maneja storage permissions en Android
- **Por qué es importante**: Separa toda la lógica compleja del UI, haciendo el código más testeable y mantenible
- **Relaciones**: 
  - Usa modelos `Mod` y `VersionHistory`
  - Es consumido por `HomePage` para todas las operaciones de datos
- **Beneficio para escalabilidad**: 
  - Permite cambiar implementación de storage sin afectar UI
  - Facilita testing unitario de lógica de negocio
  - Posibilita agregar nuevas fuentes de datos (API, base de datos)

---

## Carpeta `pages/`

### **home_page.dart**
**Responsabilidad**: Pantalla principal y controlador de la interfaz de usuario.
- **Qué hace**:
  - **Gestión de estado**: Maneja loading, refreshing, filtros, idioma
  - **Interacciones de usuario**: Agregar mods, búsquedas, actualizaciones
  - **Coordinación de servicios**: Conecta UI con `ModManager`
  - **Navegación externa**: Manejo de URLs (YouTube, descarga de mods)
  - **Gestión de permisos**: Solicita permisos de storage en Android
- **Por qué es importante**: Es la orquestadora principal que conecta servicios con widgets
- **Relaciones**:
  - Usa `ModManager` para operaciones de datos
  - Usa `ModCard` para mostrar cada mod
  - Usa `AppStrings` para traducciones
  - Consume modelos `Mod` y `VersionHistory`
- **Beneficio para escalabilidad**: Separar en page permite agregar nuevas pantallas y navegación sin impactar la lógica central

---

## Carpeta `widgets/`

### **mod_card.dart**
**Responsabilidad**: Widget reutilizable para mostrar información de un mod individual.
- **Qué hace**:
  - **Presentación de datos**: Muestra título, versión, tags, descripción
  - **Indicadores visuales**: Marca mods prioritarios con estrella
  - **Botones de acción**: Ver web, descargar, eliminar, toggle prioridad
  - **Adaptación de estado**: Se deshabilita durante operaciones de refresh
- **Por qué es importante**: Separa la lógica de presentación de un mod del resto de la aplicación
- **Relaciones**:
  - Recibe modelo `Mod` como parámetro
  - Recibe callbacks desde `HomePage` para las acciones
  - Usa función de traducción pasada por parámetro
- **Beneficio para escalabilidad**: 
  - Reutilizable en otras pantallas (ej: pantalla de detalles)
  - Fácil de modificar diseño sin impactar lógica de negocio
  - Testeable de forma aislada

---

## Carpeta `l10n/`

### **strings.dart**
**Responsabilidad**: Centralización de textos y soporte multiidioma (ES/EN).
- **Qué hace**:
  - **Almacena traducciones**: Mapa con textos en español e inglés
  - **Proporciona interfaz**: Estructura clara para acceder a textos por clave
  - **Soporte de localización**: Base para internacionalización completa
- **Por qué es importante**: Centraliza todos los textos, facilitando traducciones y mantenimiento
- **Relaciones**: 
  - Usado por `HomePage` para obtener textos traducidos
  - Pasado como parámetro a `ModCard` via función de traducción
- **Beneficio para escalabilidad**:
  - Fácil agregar nuevos idiomas
  - Facilita encontrar y modificar textos
  - Base para implementar localización automática por región del dispositivo

---

## Beneficios Arquitectónicos

### **Separación de Responsabilidades**
Cada archivo tiene una responsabilidad clara y específica, evitando código espagueti.

### **Testabilidad**
- `ModManager` puede testearse sin UI
- `ModCard` puede testearse con datos mock
- Modelos pueden validarse independientemente

### **Escalabilidad**
- **Nuevas pantallas**: Agregar a `pages/` sin modificar lógica
- **Nuevos widgets**: Crear en `widgets/` reutilizando servicios
- **Nuevas fuentes de datos**: Modificar solo `ModManager`
- **Nuevos idiomas**: Agregar a `AppStrings`

### **Mantenibilidad**
- Bugs se localizan fácilmente por responsabilidad
- Cambios en UI no afectan lógica de negocio
- Refactoring es más seguro con dependencias claras

### **Colaboración en Equipo**
- Desarrolladores pueden trabajar en paralelo en diferentes capas
- Code reviews son más enfocados por responsabilidad
- Onboarding de nuevos desarrolladores es más rápido con estructura clara

Esta arquitectura permite que el proyecto crezca de manera sostenible, manteniendo la calidad del código y facilitando el mantenimiento a largo plazo.
