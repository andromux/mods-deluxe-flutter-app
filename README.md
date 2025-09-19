# Flutter Project Documentation - SM64COOPDX Mod Manager

- [Leer Manual en español](./README-ES.md)
- [AI Chat for this Project](https://deepwiki.com/andromux/mods-deluxe-flutter-app)


<div align="center">

  <h3>¿Did you like this repository?</h3>
  <p>Give me a star or make a fork if you want to contribute!</p>

  <a href="https://github.com/andromux/mods-deluxe-flutter-app/stargazers">
    <img src="https://img.shields.io/github/stars/andromux/mods-deluxe-flutter-app?style=social" alt="GitHub Stars mods-deluxe-flutter-app"/>
  </a>

  <a href="https://github.com/andromux/mods-deluxe-flutter-app/fork">
    <img src="https://img.shields.io/github/forks/andromux/mods-deluxe-flutter-app?style=social" alt="GitHub Forks mods-deluxe-flutter-app"/>
  </a>

</div>

## General Architecture

This project is organized following a **layered architecture pattern** that clearly separates responsibilities:
- **Presentation** (UI/Widgets)
- **Business Logic** (Services)
- **Data** (Models)
- **Configuration** (App/Main)
- **Resources** (Localization)

This structure facilitates maintenance, testing, scalability, and team collaboration.

---

## Root Files

### **main.dart**
**Responsibility**: Single, minimalist entry point of the application.
- **What it does**: Executes the `main()` function that initializes `ModManagerApp`
- **Why it's important**: Keeps startup simple and delegates all configuration to `app.dart`
- **Relationships**: Imports and executes `ModManagerApp` from `app.dart`
- **Scalability benefit**: Being minimalist allows configuration changes without touching the entry point

### **app.dart**
**Responsibility**: Central configuration of the Flutter application.
- **What it does**: Defines the `MaterialApp` with dark theme, title, and initial route to `HomePage`
- **Why it's important**: Centralizes global configurations (theme, routes, future localization)
- **Relationships**: Imports `HomePage` and sets it as the initial screen
- **Scalability benefit**: Makes it easy to add new routes, themes, or global configurations without impacting other files

---

## `models/` Folder

### **mod.dart**
**Responsibility**: Main data model representing an SM64 mod.
- **What it does**: Defines the `Mod` structure with properties like title, version, description, URL, etc.
- **Key functionalities**:
  - JSON serialization (`toJson()`, `fromJson()`) for persistence
  - `copyWith()` method for creating immutable copies
  - Validation and default values
- **Why it's important**: It's the data heart of the application - everything revolves around mods
- **Relationships**: Used by `ModManager`, `HomePage`, `ModCard`, and references `VersionHistory`
- **Scalability benefit**: Centralizes data structure, facilitating schema changes and validations

### **version_history.dart**
**Responsibility**: Model for version history of each mod.
- **What it does**: Simple structure with version, date, and change description
- **Key functionalities**: JSON serialization to save complete history
- **Why it's important**: Allows tracking updates and changes in mods over time
- **Relationships**: Used within the `Mod` model as a history list
- **Scalability benefit**: Allows adding additional fields to history without breaking existing functionality

---

## `services/` Folder

### **mod_manager.dart**
**Responsibility**: Central business logic and application service layer.
- **What it does**:
  - **Storage management**: Handles JSON files in local/external storage
  - **Web scraping**: Extracts mod information from URLs using `html` parser
  - **CRUD operations**: Add, remove, update favorites
  - **Filtering and sorting**: Searches and mod classification
  - **Permission management**: Handles storage permissions on Android
- **Why it's important**: Separates all complex logic from UI, making code more testable and maintainable
- **Relationships**:
  - Uses `Mod` and `VersionHistory` models
  - Consumed by `HomePage` for all data operations
- **Scalability benefit**:
  - Allows changing storage implementation without affecting UI
  - Facilitates unit testing of business logic
  - Enables adding new data sources (API, database)

---

## `pages/` Folder

### **home_page.dart**
**Responsibility**: Main screen and user interface controller.
- **What it does**:
  - **State management**: Handles loading, refreshing, filters, language
  - **User interactions**: Add mods, searches, updates
  - **Service coordination**: Connects UI with `ModManager`
  - **External navigation**: URL handling (YouTube, mod downloads)
  - **Permission management**: Requests storage permissions on Android
- **Why it's important**: It's the main orchestrator connecting services with widgets
- **Relationships**:
  - Uses `ModManager` for data operations
  - Uses `ModCard` to display each mod
  - Uses `AppStrings` for translations
  - Consumes `Mod` and `VersionHistory` models
- **Scalability benefit**: Separating into pages allows adding new screens and navigation without impacting central logic

---

## `widgets/` Folder

### **mod_card.dart**
**Responsibility**: Reusable widget to display individual mod information.
- **What it does**:
  - **Data presentation**: Shows title, version, tags, description
  - **Visual indicators**: Marks priority mods with star
  - **Action buttons**: View web, download, delete, toggle priority
  - **State adaptation**: Disables during refresh operations
- **Why it's important**: Separates mod presentation logic from the rest of the application
- **Relationships**:
  - Receives `Mod` model as parameter
  - Receives callbacks from `HomePage` for actions
  - Uses translation function passed as parameter
- **Scalability benefit**:
  - Reusable in other screens (e.g., details screen)
  - Easy to modify design without impacting business logic
  - Testable in isolation

---

## `l10n/` Folder

### **strings.dart**
**Responsibility**: Text centralization and multi-language support (ES/EN).
- **What it does**:
  - **Stores translations**: Map with texts in Spanish and English
  - **Provides interface**: Clear structure to access texts by key
  - **Localization support**: Base for complete internationalization
- **Why it's important**: Centralizes all texts, facilitating translations and maintenance
- **Relationships**:
  - Used by `HomePage` to get translated texts
  - Passed as parameter to `ModCard` via translation function
- **Scalability benefit**:
  - Easy to add new languages
  - Facilitates finding and modifying texts
  - Base for implementing automatic localization by device region

---

## Architectural Benefits

### **Separation of Concerns**
Each file has a clear and specific responsibility, avoiding spaghetti code.

### **Testability**
- `ModManager` can be tested without UI
- `ModCard` can be tested with mock data
- Models can be validated independently

### **Scalability**
- **New screens**: Add to `pages/` without modifying logic
- **New widgets**: Create in `widgets/` reusing services
- **New data sources**: Modify only `ModManager`
- **New languages**: Add to `AppStrings`

### **Maintainability**
- Bugs are easily located by responsibility
- UI changes don't affect business logic
- Refactoring is safer with clear dependencies

### **Team Collaboration**
- Developers can work in parallel on different layers
- Code reviews are more focused by responsibility
- Onboarding new developers is faster with clear structure

This architecture allows the project to grow sustainably, maintaining code quality and facilitating long-term maintenance.
