/// Configuración principal de la aplicación MaterialApp
/// Maneja el tema, rutas y navegación principal

import 'package:flutter/material.dart';
import 'pages/home_page.dart';

class ModManagerApp extends StatelessWidget {
  const ModManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SM64 Mod Manager',
      theme: ThemeData.dark(),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}